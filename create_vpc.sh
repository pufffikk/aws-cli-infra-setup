# Creating a VPC
AMI_ID=ami-04999cd8f2624f834
vpcid=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/25 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=Script-Vpc}]' \
    --query 'Vpc.VpcId' \
    --output text)

echo "VPC created: $vpcid"

# Next Step -> DNS Hostnames

#aws ec2 modify-vpc-attribute \
#    --vpc-id $vpcid \
#    --enable-dns-hostnames "{\"Value\":true}"

# Create Public Subnet

pubsub1=$(aws ec2 create-subnet \
  --vpc-id $vpcid \
  --cidr-block 10.0.0.0/27 \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public Subnet}]' \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Public Subnet created: $pubsub1"

# Enable Public IP on launch

aws ec2 modify-subnet-attribute \
  --subnet-id $pubsub1 \
  --map-public-ip-on-launch


# Create Private Subnet

privsub1=$(aws ec2 create-subnet \
  --vpc-id $vpcid \
  --cidr-block 10.0.0.64/26 \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private Subnet}]' \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Private Subnet created: $privsub1"

# Creating an IGW

igwid=$(aws ec2 create-internet-gateway \
	--tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=Script-IGW}]" \
--query 'InternetGateway.InternetGatewayId' \
--output text)

echo "Internet Gateway created: $igwid"

# attaching the IGW to the VPC

aws ec2 attach-internet-gateway --internet-gateway-id $igwid --vpc-id $vpcid
  
echo "IGW attached: $igwid"

# Create Route Table

rtbpubid1=$(aws ec2 create-route-table \
    --vpc-id $vpcid \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=Public Route Table}]" \
    --query 'RouteTable.RouteTableId' \
    --output text)

# Create a Route

aws ec2 create-route \
    --route-table-id $rtbpubid1 \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $igwid

# Subnet Associations

aws ec2 associate-route-table --subnet-id $pubsub1 --route-table-id $rtbpubid1

echo "Public route table created and associated."

# Allocate Elastic IP for NAT
EIP_ALLOC_ID=$(aws ec2 allocate-address --domain vpc \
  --query 'AllocationId' --output text)

# Create NAT Gateway
NAT_GW_ID=$(aws ec2 create-nat-gateway --subnet-id $pubsub1 \
  --allocation-id $EIP_ALLOC_ID --query 'NatGateway.NatGatewayId' --output text)

# Wait until NAT gateway is available
echo "Waiting for NAT Gateway to become available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID

# Create private route table and associate with private subnet
PRIVATE_RT_ID=$(aws ec2 create-route-table --vpc-id $vpcid \
  --query 'RouteTable.RouteTableId' --output text)

aws ec2 create-route --route-table-id $PRIVATE_RT_ID --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_GW_ID

aws ec2 associate-route-table --subnet-id $privsub1 --route-table-id $PRIVATE_RT_ID

# Create Security Group for Bastion Host

# Allow SSH from your IP to public instance
MY_IP=$(curl -s https://checkip.amazonaws.com)/32

bastionsgid=$(aws ec2 create-security-group \
  --group-name "Bastion Security Group" \
  --description "Allow SSH" \
  --vpc-id $vpcid \
  --query 'GroupId' \
  --output text)

echo "Security Group created: $bastionsgid"

# Adding Ingress Rule for Bastion SG

aws ec2 authorize-security-group-ingress \
    --group-id $bastionsgid \
    --protocol tcp \
    --port 22 \
    --cidr $MY_IP
# Change this either to 0.0.0.0 -> everyone
# Or change this to you own IP -> best practice

# Launch Bastion Host EC2

# User data (Amazon Linux 2 - auto update)
USER_DATA=$(base64 <<EOF
#!/bin/bash
yum update -y
EOF
)

aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.micro \
  --subnet-id $pubsub1 \
  --key-name vockey \
  --associate-public-ip-address \
  --user-data $USER_DATA \
  --security-group-ids $bastionsgid \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value="Bastion Server"}]'


# Create Security Group for Private Instance
# Allow SSH only from Bastion/CIDR 

privatesgid=$(aws ec2 create-security-group \
  --group-name "Private Instance Security Group" \
  --description "Allow SSH only from Bastion" \
  --vpc-id $vpcid \
  --query 'GroupId' \
  --output text)

aws ec2 authorize-security-group-ingress \
    --group-id $privatesgid \
    --protocol tcp \
    --port 22 \
    --cidr 10.0.0.0/26

# Launch instance in private subnet

aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.micro \
  --subnet-id $privsub1 \
  --key-name vockey \
  --user-data $USER_DATA \
  --security-group-ids $privatesgid \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value="Private Server"}]'



# [Optional] NAT Gateway -> if the private instance needs internet access













