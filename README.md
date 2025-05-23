# AWS VPC and EC2 Deployment via CLI

## 📖 Project Overview

This project automates the deployment of a basic AWS infrastructure using the AWS Command Line Interface (CLI). It sets up a secure and functional environment with networking and compute resources.

The main components created by the script include:

- A custom Virtual Private Cloud (VPC)
- Public and private subnets
- Route tables with appropriate routing rules
- Internet Gateway for public internet access
- NAT Gateway for private instance outbound access
- EC2 instances (1 public, 1 private)
- SSH access for maintenance
- System updates automatically applied at launch

## 🚀 What It Provides

- **1 Public EC2 Instance**: Accessible via the internet with SSH; used as a bastion or web server.
- **1 Private EC2 Instance**: No public IP; can access the internet via NAT Gateway.
- **Secure Networking**: Public and private subnets with route tables, and security groups restricting access.
- **Infrastructure-as-Code**: All resources created using a bash script with AWS CLI.

## 📦 Requirements

- AWS CLI installed and configured (`aws configure`)
- An Amazon Linux 2 AMI ID (update the script with a valid ID for your region)
- Bash-compatible shell (Linux/macOS/WSL on Windows)

## 📥 How to Use

### 1. Clone the Repository

### 2. Open create_vpc.sh and update the following placeholders:

	Replace the AMI_ID (ami-xxxxxxxxxxxxxxxxx) with an Amazon Linux 2 AMI ID for your AWS region

### 3. Make the Script Executable
	chmod +x create_vpc.sh

### 4. Run the Script
	./create_vpc.sh

The script will:

Create a VPC with subnets, IGW, NAT Gateway, route tables

Create and configure public/private EC2 instances

Set up SSH access

Apply system updates automatically via user data