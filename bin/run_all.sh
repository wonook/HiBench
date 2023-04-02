#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -u

current_dir=`dirname "$0"`
root_dir=`cd "${current_dir}/.."; pwd`

. ${root_dir}/bin/functions/color.sh

for benchmark in `cat $root_dir/conf/benchmarks_run.lst`; do
    if [[ $benchmark == \#* ]]; then
        continue
    fi

    echo -e "${UYellow}${BYellow}Prepare ${Yellow}${UYellow}${benchmark} ${BYellow}...${Color_Off}"
    benchmark="${benchmark/.//}"

    WORKLOAD=$root_dir/bin/workloads/${benchmark}
    #echo -e "${BCyan}Exec script: ${Cyan}${WORKLOAD}/prepare/prepare.sh${Color_Off}"
    #"${WORKLOAD}/prepare/prepare.sh"

    result=$?
    if [ $result -ne 0 ]
    then
    echo "ERROR: ${benchmark} prepare failed!"
        exit $result
    fi

    for framework in `cat $root_dir/conf/frameworks.lst`; do
    if [[ $framework == \#* ]]; then
        continue
    fi

    if [ $benchmark == "micro/dfsioe" ] && [ $framework == "spark" ]; then
        continue
    fi
    if [ $benchmark == "micro/repartition" ] && [ $framework == "hadoop" ]; then
        continue
    fi
    if [ $benchmark == "websearch/nutchindexing" ] && [ $framework == "spark" ]; then
        continue
    fi
    if [ $benchmark == "graph/nweight" ] && [ $framework == "hadoop" ]; then
        continue
    fi
    if [ $benchmark == "graph/pagerank" ] && [ $framework == "hadoop" ]; then
	    continue
	  fi
    if [ $benchmark == "ml/lr" ] && [ $framework == "hadoop" ]; then
        continue
    fi
    if [ $benchmark == "ml/als" ] && [ $framework == "hadoop" ]; then
        continue
    fi
    if [ $benchmark == "ml/svm" ] && [ $framework == "hadoop" ]; then
        continue
    fi
    if [ $benchmark == "ml/pca" ] && [ $framework == "hadoop" ]; then
        continue
    fi
    if [ $benchmark == "ml/gbt" ] && [ $framework == "hadoop" ]; then
         continue
    fi
    if [ $benchmark == "ml/rf" ] && [ $framework == "hadoop" ]; then
          continue
    fi  
    if [ $benchmark == "ml/svd" ] && [ $framework == "hadoop" ]; then
        continue
    fi      
    if [ $benchmark == "ml/linear" ] && [ $framework == "hadoop" ]; then
        continue
    fi
    if [ $benchmark == "ml/lda" ] && [ $framework == "hadoop" ]; then
        continue
    fi
    if [ $benchmark == "ml/gmm" ] && [ $framework == "hadoop" ]; then
        continue
    fi
    if [ $benchmark == "ml/correlation" ] && [ $framework == "hadoop" ]; then
        continue
    fi
    if [ $benchmark == "ml/summarizer" ] && [ $framework == "hadoop" ]; then
         continue
    fi

    for cost in LRU LRC MRD GD
    do
        DATE=`date +"%m-%d"`
        TIMESTAMP=`timestamp`
        DAG_PATH=""        

        for mode in "profiling" #"actual"
            DIR=${WORKLOAD_RESULT_FOLDER}/$DATE/${TIMESTAMP}-${cost}-${YARN_NUM_EXECUTORS}executors-${YARN_EXECUTOR_CORES}cores-${SPARK_YARN_EXECUTOR_MEMORY}mem-${SPARK_YARN_DRIVER_MEMORY}drivermem
            mkdir -p $DIR
            EXTRA_ARGS=""

            if $mode == "profiling"; then
                echo "Running profiling"
                SAMPLING_TIMEOUT=60
                SAMPLING_JOBS=1

                EXTRA_ARGS="--conf 'spark.blaze.isProfileRun=true' "

                # ./bin/spark_killer.sh $SAMPLING_TIMEOUT &
            elif $DAG_PATH != ""; then
                echo "Running actual based on $DAG_PATH"

                AUTOCACHING=false
                SAMPLING_JOBS=1
                LAZY_AUTOCACHING=false
                AUTOUNPERSIST=false
                EXTRA_ARGS="--conf 'spark.blaze.dagPath=$DAG_PATH' \
                    --conf 'spark.blaze.autoCaching=$AUTOCACHING' \
                    --conf 'spark.blaze.isProfileRun=false' \
                    --conf 'spark.blaze.profileNumJobs=$SAMPLING_JOBS' \
                    --conf 'spark.blaze.lazyAutoCaching=$LAZY_AUTOCACHING' \
                    --conf 'spark.blaze.autoUnpersist=$AUTOUNPERSIST' \
                    --conf 'spark.blaze.costFunction=$cost'"
            else
                echo "NO DAG_PATH provided! Run profiling first to run blaze."
                    exit
            fi

            echo -e "${UYellow}${BYellow}Run ${Yellow}${UYellow}${benchmark}/${framework}${Color_Off}"
            echo -e "${BCyan}Exec script: ${Cyan}$WORKLOAD/${framework}/run.sh${Color_Off}"
            start_time="$(date -u +%s)"
            $WORKLOAD/${framework}/run.sh ${EXTRA_ARGS}
            end_time="$(date -u +%s)"

            result=$?
            if [ $result -ne 0 ]
            then
                echo -e "${On_IRed}ERROR: ${benchmark}/${framework} failed to run successfully.${Color_Off}"
                    exit $result
            elif $mode == "profiling"
            then
                # get dag path 
                APP_ID=`cat ${WORKLOAD_RESULT_FOLDER}/bench.log  | grep -oP "application_[0-9]*_[0-9]*" | tail -n 1`
                echo "Getting sampled lineage... $APP_ID"
                sleep 5
                hdfs dfs -get /spark_history/$APP_ID $DIR/sampled_lineage.txt
                if [ ! -f "$DIR/sampled_lineage.txt" ]; then
                    hdfs dfs -get /spark_history/"${APP_ID}.inprogress" $DIR/sampled_lineage.txt
                fi
                DAG_PATH=$DIR/sampled_lineage.txt
            else
                # get dag path 
                APP_ID=`cat ${WORKLOAD_RESULT_FOLDER}/bench.log  | grep -oP "application_[0-9]*_[0-9]*" | tail -n 1`
                echo "parsing result... $APP_ID"
                sleep 5
                ~/hadoop/bin/yarn logs -applicationId $APP_ID > $DIR/${mode}-yarn.log

                # history parsing 
                if [[ ${#APP_ID} -gt 5 ]]; then
                    hdfs dfs -get /spark_history/$APP_ID $DIR/${mode}-sparkhistory.txt
                fi
            fi

            mv ${WORKLOAD_RESULT_FOLDER}/bench.log $DIR/${mode}-bench.log
            mv ${WORKLOAD_RESULT_FOLDER}/monitor.log $DIR/${mode}-monitor.log
            mv ${WORKLOAD_RESULT_FOLDER}/monitor.html $DIR/${mode}-monitor.html
            echo "successfully ended: find the log at ${DIR}"

            ######################
            ### Slack Summary
            ######################

            EXCEPTION=`cat $DIR/${mode}-bench.log | grep Exception | head -3`
            CANCEL=`cat $DIR/${mode}-bench.log | grep cancelled because | head -3`
            ABORT=`cat $DIR/${mode}-bench.log | grep aborted | head -3`

            if [ -z "${EXCEPTION// }" ]; then
            echo "No exception"
            else
                message="Exception happended! $EXCEPTION\n"
            fi
            if [ -z "${CANCEL// }" ]; then
            echo "No cancellation"
            else
                message="Job cancelled! $CANCEL\n"
            fi
            if [ -z "${ABORT// }" ]; then
            echo "Not aborted"
            else
                message="Job aborted! $ABORT\n"
            fi

            COMMIT=`git log --pretty=format:'%h' -n 1`
            jct="$(($end_time-$start_time))"
            # sampling_time="$(($sampling_end-$sampling_start))"

            message=$message" git commit $COMMIT\n"
            message=$message" $DIR\n"
            message=$message" App $APP_ID for $benchmark on $framework with $cost\n"
            # message=$message" Args $ARGS\n"
            # message=$message" Profiling $sampling_time sec (timeout $SAMPLING_TIMEOUT)\n"
            message=$message" $mode JCT $jct sec\n"

            ./scripts/send_slack.sh  $message
            #####

        done
    done
    done
done

echo "Run all done!"
