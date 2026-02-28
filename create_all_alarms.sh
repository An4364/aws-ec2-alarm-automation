#!/bin/bash

set -e

# ==============================
# CONFIGURATION
# ==============================

DEFAULT_REGION="ap-south-1"
SNS_TOPIC_NAME="ec2-alarms-topic"

# ==============================
# INPUT VALIDATION
# ==============================

if [ $# -lt 2 ]; then
    echo "Usage: $0 <alarm-base-name> <instance-id> [region]"
    exit 1
fi

ALARM_BASE_NAME="$1"
INSTANCE_ID="$2"
REGION="${3:-$DEFAULT_REGION}"

if [[ ! "$INSTANCE_ID" =~ ^i-[a-f0-9]{8,17}$ ]]; then
    echo "Invalid EC2 Instance ID format"
    exit 1
fi

echo "====================================="
echo "Creating alarms for: $INSTANCE_ID"
echo "Region: $REGION"
echo "====================================="

# ==============================
# CHECK AWS CLI
# ==============================

command -v aws >/dev/null 2>&1 || {
    echo "AWS CLI not installed"
    exit 1
}

# ==============================
# VERIFY INSTANCE EXISTS
# ==============================

aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text >/dev/null

# ==============================
# CREATE OR GET SNS TOPIC
# ==============================

SNS_TOPIC_ARN=$(aws sns create-topic \
    --name "$SNS_TOPIC_NAME" \
    --region "$REGION" \
    --query 'TopicArn' \
    --output text)

echo "SNS Topic ARN: $SNS_TOPIC_ARN"

# ==============================
# EC2 ACTION ARNs
# ==============================

REBOOT_ARN="arn:aws:automate:${REGION}:ec2:reboot"
RECOVER_ARN="arn:aws:automate:${REGION}:ec2:recover"

# ==============================
# CPU ALARM
# ==============================

aws cloudwatch put-metric-alarm \
    --alarm-name "${ALARM_BASE_NAME}-HighCPU" \
    --alarm-description "High CPU for $INSTANCE_ID" \
    --namespace "AWS/EC2" \
    --metric-name "CPUUtilization" \
    --dimensions Name=InstanceId,Value="$INSTANCE_ID" \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --evaluation-periods 2 \
    --comparison-operator GreaterThanThreshold \
    --alarm-actions "$SNS_TOPIC_ARN" \
    --ok-actions "$SNS_TOPIC_ARN" \
    --treat-missing-data notBreaching \
    --actions-enabled \
    --region "$REGION"

echo "CPU Alarm Created"

# ==============================
# INSTANCE STATUS FAILED → REBOOT
# ==============================

aws cloudwatch put-metric-alarm \
    --alarm-name "${ALARM_BASE_NAME}-InstanceStatusFailed" \
    --alarm-description "Instance status check failed for $INSTANCE_ID" \
    --namespace "AWS/EC2" \
    --metric-name "StatusCheckFailed_Instance" \
    --dimensions Name=InstanceId,Value="$INSTANCE_ID" \
    --statistic Maximum \
    --period 60 \
    --threshold 1 \
    --evaluation-periods 2 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --alarm-actions "$SNS_TOPIC_ARN" "$REBOOT_ARN" \
    --ok-actions "$SNS_TOPIC_ARN" \
    --treat-missing-data notBreaching \
    --actions-enabled \
    --region "$REGION"

echo "Instance Status Alarm Created (Auto Reboot Enabled)"

# ==============================
# SYSTEM STATUS FAILED → RECOVER
# ==============================

aws cloudwatch put-metric-alarm \
    --alarm-name "${ALARM_BASE_NAME}-SystemStatusFailed" \
    --alarm-description "System status check failed for $INSTANCE_ID" \
    --namespace "AWS/EC2" \
    --metric-name "StatusCheckFailed_System" \
    --dimensions Name=InstanceId,Value="$INSTANCE_ID" \
    --statistic Maximum \
    --period 60 \
    --threshold 1 \
    --evaluation-periods 2 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --alarm-actions "$SNS_TOPIC_ARN" "$RECOVER_ARN" \
    --ok-actions "$SNS_TOPIC_ARN" \
    --treat-missing-data notBreaching \
    --actions-enabled \
    --region "$REGION"

echo "System Status Alarm Created (Auto Recover Enabled)"

echo ""
echo "====================================="
echo "All alarms created successfully ✅"
echo "Check CloudWatch → Alarms section"
echo "====================================="