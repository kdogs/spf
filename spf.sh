#!/bin/bash

# Recursive SPF

if [[ $# -eq 1 ]]
then
	sleep 0
else
	echo "Usage: spf [query domain]"
	exit 1;
fi

# Show original answer section
echo ANSWER:
dig +short txt $1
printf "\n"

# Store answer in string 'str'
q=$1
str=$(dig +short txt $q | grep spf)
sameline=0
rdir=0

#Function to do recursive SPF lookup.
function recursive_spf ()
{
local s="$1"

# Remove all double quotes before parsing string
s=$(echo $s | sed s/\"//g)
for word in $s
	do	
		if [[ $word == redirect* ]]
			then	
				rdir=1
				red1=$(echo $word | cut -d "=" -f 2)
				recursive_spf "$red1"
		elif [[ $word == include* ]]
			then
				inc1=$(echo $word | cut -d ":" -f 2)
				inc2=$(dig +short txt $inc1 | grep spf)
				recursive_spf "$inc2"
		elif [[ $word == *"v=spf1"* ]] || [[ $word == *"all"* ]]
			then	
				sleep 0
		elif [[ $word == mx ]]
			then
				printf "\n"
				echo "mx:$q"
				echo "$(dig +short mx $q | awk '{ print $2 }' | xargs -I{} sh -c 'dig +short {}')"
				printf "\n" 
		# TODO: Recursion for MX directives other than standalone 'mx:' for queried domain.
		#elif [[ $word == "mx:"* ]]
			#then
		elif [[ $word == a ]]
                        then
				printf "\n"
				echo "a:$q"
				dig +short $q | xargs -I{} sh -c 'echo {}'
				printf "\n"
		# TODO: Recursion for A record directives other than standalone 'a:' for queried domain.
		#elif [[ $word == "a:"* ]]
			#then
		elif [[ $word == ptr ]]
			then
				echo "ptr:"$q.
		elif [[ $newline -eq 1 ]] || [[ ${#word} -lt 11 ]]
			then
				if [[ ${#word} -lt 11 ]] && [[ $word != spf* ]]
					then
						echo $word | tr "\\n" "\ " | tr -d ' '
						newline=1
				else
					echo $word | grep -v spf
					newline=0
				fi
		elif [[ rdir -eq 1 ]]
			then
				rdir=0
				catch_rdir=$(dig +short txt $word | grep spf)
				recursive_spf "$catch_rdir"
		else
			echo $word
		fi 
	done
}

recursive_spf "$str"
