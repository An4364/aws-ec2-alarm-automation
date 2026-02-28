# AWS EC2 Alarm Automation

This script automates the creation of CloudWatch alarms for EC2 instances.

## 🚀 What It Creates

- High CPU Utilization Alarm (80%)
- Instance Status Check Failed Alarm (Auto Reboot)
- System Status Check Failed Alarm (Auto Recover)
- SNS Topic for Notifications

---

## 📌 Prerequisites

Before running the script:

- AWS CLI installed
- AWS CLI configured using:
  aws configure
- IAM user/role must have below permissions

### Required IAM Permissions

- ec2:DescribeInstances
- cloudwatch:PutMetricAlarm
- sns:CreateTopic
- sns:Subscribe
- sns:ListTopics

Example IAM Policy:

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "cloudwatch:PutMetricAlarm",
        "sns:CreateTopic",
        "sns:Subscribe",
        "sns:ListTopics"
      ],
      "Resource": "*"
    }
  ]
}

---

## ▶️ How to Run

Make script executable:

chmod +x create_all_alarms.sh

Run script:

./create_all_alarms.sh <alarm-name> <instance-id> <region>

Example:

./create_all_alarms.sh myalarm i-028514df26a390e57 ap-south-1

---

## 📊 Output

Script will create:

- 3 CloudWatch alarms
- 1 SNS topic
- Email notification subscription (if configured)

---

## 📝 License

MIT
