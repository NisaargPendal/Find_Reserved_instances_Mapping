#!/bin/bash

# AWS Reserved Instance to Running Instance Detailed Mapping
# Shows exact Reserved Instance IDs and which instances are using that capacity

echo "=== AWS RESERVED INSTANCE USAGE MAPPING ==="
echo "Region: us-east-1"
echo "Date: $(date)"
echo ""

# Get Reserved Instances with detailed info
echo "=== ACTIVE RESERVED INSTANCES ==="
printf "%-20s %-12s %-15s %-5s %-20s %-8s\n" "Reserved-Instance-ID" "Type" "AZ" "Count" "Platform" "State"
printf "%-20s %-12s %-15s %-5s %-20s %-8s\n" "--------------------" "------------" "---------------" "-----" "--------------------" "--------"
aws ec2 describe-reserved-instances \
    --region us-east-1 \
    --filters "Name=state,Values=active" \
    --query 'ReservedInstances[*].[ReservedInstancesId,InstanceType,AvailabilityZone,InstanceCount,ProductDescription,State]' \
    --output text | while read -r ri_id type az count platform state; do
    printf "%-20s %-12s %-15s %-5s %-20s %-8s\n" "$ri_id" "$type" "$az" "$count" "$platform" "$state"
done

echo ""
echo "=== RUNNING INSTANCES ==="
printf "%-20s %-12s %-15s %-15s %-25s\n" "Instance-ID" "Type" "AZ" "Platform" "Name"
printf "%-20s %-12s %-15s %-15s %-25s\n" "--------------------" "------------" "---------------" "---------------" "-------------------------"
aws ec2 describe-instances \
    --region us-east-1 \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,AvailabilityZone,Platform,Tags[?Key==`Name`].Value|[0]]' \
    --output text | while read -r instance_id type az platform name; do
    if [ "$platform" = "None" ] || [ -z "$platform" ]; then
        platform="Linux/UNIX"
    fi
    if [ -z "$name" ]; then
        name="(no name)"
    fi
    printf "%-20s %-12s %-15s %-15s %-25s\n" "$instance_id" "$type" "$az" "$platform" "$name"
done

echo ""
echo "=== DETAILED RESERVED INSTANCE MAPPING ==="
echo ""

# Create temporary files
RI_FILE=$(mktemp)
INSTANCES_FILE=$(mktemp)

# Get Reserved Instances data
aws ec2 describe-reserved-instances \
    --region us-east-1 \
    --filters "Name=state,Values=active" \
    --query 'ReservedInstances[*].[ReservedInstancesId,InstanceType,AvailabilityZone,InstanceCount,ProductDescription]' \
    --output text > $RI_FILE

# Get running instances data
aws ec2 describe-instances \
    --region us-east-1 \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,AvailabilityZone,Platform,LaunchTime]' \
    --output text > $INSTANCES_FILE

# Process each Reserved Instance
while IFS=$'\t' read -r ri_id ri_type ri_az ri_count ri_platform; do
    echo "┌─────────────────────────────────────────────────────────────────────────────────────"
    echo "│ RESERVED INSTANCE: $ri_id"
    echo "│ Type: $ri_type | AZ: $ri_az | Capacity: $ri_count | Platform: $ri_platform"
    echo "├─────────────────────────────────────────────────────────────────────────────────────"

    # Find matching running instances
    matching_instances=()
    while IFS=$'\t' read -r instance_id instance_type instance_az platform launch_time; do
        # Default platform handling
        if [ "$platform" = "None" ] || [ -z "$platform" ]; then
            platform="Linux/UNIX"
        fi

        # Check if this instance matches the Reserved Instance
        if [ "$instance_type" = "$ri_type" ] && [ "$instance_az" = "$ri_az" ]; then
            # Platform matching logic
            platform_match=false
            if [[ "$platform" == *"Windows"* && "$ri_platform" == *"Windows"* ]]; then
                platform_match=true
            elif [[ "$platform" == *"Linux"* && "$ri_platform" == *"Linux"* ]]; then
                platform_match=true
            elif [[ "$platform" == "Linux/UNIX" && "$ri_platform" == *"Linux"* ]]; then
                platform_match=true
            fi

            if [ "$platform_match" = true ]; then
                matching_instances+=("$instance_id|$instance_type|$instance_az|$platform|$launch_time")
            fi
        fi
    done < $INSTANCES_FILE

    # Display results
    if [ ${#matching_instances[@]} -eq 0 ]; then
        echo "│ ❌ NO MATCHING RUNNING INSTANCES FOUND"
        echo "│ Status: UNUSED RESERVED CAPACITY"
    else
        echo "│ ✅ MATCHING RUNNING INSTANCES:"
        count=1
        for instance in "${matching_instances[@]}"; do
            IFS='|' read -r inst_id inst_type inst_az inst_platform inst_launch <<< "$instance"
            if [ $count -le $ri_count ]; then
                echo "│   [$count/$ri_count] $inst_id ($inst_type) - USING RESERVED CAPACITY"
            else
                echo "│   [EXTRA] $inst_id ($inst_type) - USING ON-DEMAND"
            fi
            echo "│           Platform: $inst_platform | Launch: $inst_launch"
            ((count++))
        done

        # Show utilization status
        if [ ${#matching_instances[@]} -lt $ri_count ]; then
            unused=$((ri_count - ${#matching_instances[@]}))
            echo "│ ⚠️  UNDERUTILIZED: $unused/$ri_count reserved capacity unused"
        elif [ ${#matching_instances[@]} -gt $ri_count ]; then
            excess=$((${#matching_instances[@]} - ri_count))
            echo "│ ⚠️  OVERUTILIZED: $excess instances using On-Demand pricing"
        else
            echo "│ ✅ PERFECTLY UTILIZED: All reserved capacity in use"
        fi
    fi

    echo "└─────────────────────────────────────────────────────────────────────────────────────"
    echo ""

done < $RI_FILE

# Summary of instances not covered by any Reserved Instance
echo "=== INSTANCES WITHOUT RESERVED COVERAGE ==="
echo ""
used_instances=()

# First, collect all instances that are covered by Reserved Instances
while IFS=$'\t' read -r ri_id ri_type ri_az ri_count ri_platform; do
    count=0
    while IFS=$'\t' read -r instance_id instance_type instance_az platform launch_time; do
        if [ "$platform" = "None" ] || [ -z "$platform" ]; then
            platform="Linux/UNIX"
        fi

        if [ "$instance_type" = "$ri_type" ] && [ "$instance_az" = "$ri_az" ]; then
            platform_match=false
            if [[ "$platform" == *"Windows"* && "$ri_platform" == *"Windows"* ]] ||
               [[ "$platform" == *"Linux"* && "$ri_platform" == *"Linux"* ]] ||
               [[ "$platform" == "Linux/UNIX" && "$ri_platform" == *"Linux"* ]]; then
                platform_match=true
            fi

            if [ "$platform_match" = true ] && [ $count -lt $ri_count ]; then
                used_instances+=("$instance_id")
                ((count++))
            fi
        fi
    done < $INSTANCES_FILE
done < $RI_FILE

# Show instances not covered
echo "Instances running on ON-DEMAND pricing:"
while IFS=$'\t' read -r instance_id instance_type instance_az platform launch_time; do
    if [[ ! " ${used_instances[@]} " =~ " ${instance_id} " ]]; then
        echo "💰 $instance_id ($instance_type) in $instance_az - ON-DEMAND BILLING"
    fi
done < $INSTANCES_FILE

# Cleanup
rm -f $RI_FILE $INSTANCES_FILE

echo ""
echo "=== LEGEND ==="
echo "✅ = Instance using Reserved Instance capacity"
echo "❌ = Reserved Instance not being used"
echo "⚠️  = Partial utilization (over/under used)"
echo "💰 = Instance billed at On-Demand rates"
