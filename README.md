# AWS Reserved Instance Finder

A bash script that maps AWS Reserved Instances to running EC2 instances, showing detailed utilization and identifying unused reserved capacity or instances running on On-Demand pricing.

## Features

This script provides comprehensive Reserved Instance analysis by displaying active Reserved Instances alongside running EC2 instances, creating detailed mappings between Reserved Instances and the instances utilizing that capacity, and identifying underutilized, overutilized, or completely unused Reserved Instances. It also highlights instances running on On-Demand pricing that could benefit from Reserved Instance coverage.

The script presents information in a clear, formatted output with visual indicators for easy interpretation of utilization status and cost optimization opportunities.

## Prerequisites

Before running this script, ensure you have the following requirements met:

**AWS CLI Installation and Configuration:**
- AWS CLI must be installed and configured with appropriate credentials
- Your AWS credentials should have permissions to describe EC2 instances and Reserved Instances
- The script currently targets the `us-east-1` region (can be modified as needed)

**Required AWS Permissions:**
- `ec2:DescribeReservedInstances`
- `ec2:DescribeInstances`

## Installation and Setup

### For Linux/macOS:

Download and prepare the script:

    # Download the script (replace with your actual download method)
    wget https://your-repo/final_reserv_instance_finder.sh
    # or
    curl -O https://your-repo/final_reserv_instance_finder.sh

    # Make the script executable
    chmod +x final_reserv_instance_finder.sh

Ensure AWS CLI is installed and configured:

    # Install AWS CLI if not already installed
    # For macOS with Homebrew:
    brew install awscli

    # For Linux (Ubuntu/Debian):
    sudo apt-get install awscli

    # Configure AWS CLI with your credentials
    aws configure

### For Windows:

**Option 1: Using Git Bash or WSL (Recommended)**

If you have Git Bash or Windows Subsystem for Linux (WSL) installed, you can run the script directly:

    # In Git Bash or WSL terminal
    chmod +x final_reserv_instance_finder.sh
    ./final_reserv_instance_finder.sh

**Option 2: Using Windows Command Prompt with Bash**

Install Git for Windows (which includes Git Bash) or use WSL to run bash scripts on Windows.

**Option 3: PowerShell Alternative**

While this script is written in bash, you can run it through WSL or convert the commands to PowerShell if needed.

## Usage

### Basic Usage:

    # Make sure the script is executable
    chmod +x final_reserv_instance_finder.sh

    # Run the script
    ./final_reserv_instance_finder.sh

### Running from Different Directories:

    # If script is in your current directory
    ./final_reserv_instance_finder.sh

    # If script is in a different directory
    /path/to/final_reserv_instance_finder.sh

    # Or add to PATH and run from anywhere
    export PATH=$PATH:/path/to/script/directory
    final_reserv_instance_finder.sh

## Output Explanation

The script generates several sections of output to provide comprehensive Reserved Instance analysis:

**Active Reserved Instances Section:**
This section lists all active Reserved Instances with their IDs, instance types, availability zones, capacity counts, platforms, and current states.

**Running Instances Section:**
Shows all currently running EC2 instances with their IDs, types, availability zones, platforms, and names (if tagged).

**Detailed Reserved Instance Mapping:**
For each Reserved Instance, this section shows exactly which running instances are utilizing that reserved capacity, indicates utilization status (perfectly utilized, underutilized, or overutilized), and identifies any unused reserved capacity.

**Instances Without Reserved Coverage:**
Lists instances that are running on On-Demand pricing and not covered by any Reserved Instance.

**Legend:**
- ✅ = Instance using Reserved Instance capacity
- ❌ = Reserved Instance not being used  
- ⚠️ = Partial utilization (over/under used)
- 💰 = Instance billed at On-Demand rates

## Customization

### Changing AWS Region:

To modify the script for a different AWS region, edit the region parameter in the AWS CLI commands:

    # Change this line in the script:
    --region us-east-1

    # To your desired region, for example:
    --region us-west-2

### Filtering by Instance Types:

You can modify the script to focus on specific instance types by adding filters to the AWS CLI commands:

    # Add instance type filter to the describe-instances command:
    --filters "Name=instance-state-name,Values=running" "Name=instance-type,Values=t3.micro,t3.small"

## Troubleshooting

**Common Issues and Solutions:**

**Permission Denied Error:**

    # Solution: Make the script executable
    chmod +x final_reserv_instance_finder.sh

**AWS CLI Not Found:**

    # Solution: Install AWS CLI
    # For macOS: brew install awscli
    # For Linux: sudo apt-get install awscli
    # For Windows: Download from AWS website

**AWS Credentials Not Configured:**

    # Solution: Configure AWS CLI
    aws configure
    # Enter your Access Key ID, Secret Access Key, region, and output format

**No Output or Empty Results:**
- Verify you're checking the correct AWS region
- Ensure your AWS credentials have the necessary permissions
- Check that you have Reserved Instances and running instances in the specified region

## Requirements Summary

- **Operating System:** Linux, macOS, or Windows (with Git Bash/WSL)
- **AWS CLI:** Version 2.0 or higher recommended
- **Bash:** Version 4.0 or higher
- **AWS Permissions:** EC2 describe permissions for instances and Reserved Instances
- **Network:** Internet connection to access AWS APIs

## Contributing

Feel free to submit issues, feature requests, or pull requests to improve this script. When contributing, please ensure your changes maintain compatibility across different operating systems and AWS regions.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Created to solve Reserved Instance tracking and optimization challenges in AWS environments.
