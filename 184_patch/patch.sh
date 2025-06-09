read -p "Please confirm that the iotex server process has been stopped [yes/no] (Default: no)" check

if [ "${check}"X != "yes"X ];then
    echo "the iotex server process is not stopped. Please stop the process first"
    exit 1
fi

#check IOTEX_HOME variable & statedb path
if [ ! $IOTEX_HOME ] || [ ! -f ${IOTEX_HOME}/data/trie.db ];then
    read -p "Input your \$IOTEX_HOME : " inputdir
    IOTEX_HOME=${inputdir}
fi

echo "IOTEX_HOME : $IOTEX_HOME"


cd $IOTEX_HOME

#download readtip file
curl https://storage.iotex.io/readtip > $IOTEX_HOME/readtip

if [ ! -f $IOTEX_HOME/readtip ];then
    echo "$IOTEX_HOME/readtip does not exist"
    exit 1
fi

chmod a+x $IOTEX_HOME/readtip

tipHeight=`$IOTEX_HOME/readtip -state-db-path=$IOTEX_HOME/data/trie.db`

if [ ! $tipHeight ];then
    echo "can't get $tipHeight"
    exit 1
fi

echo "tip height : $tipHeight"

#download the patch file
if [ $tipHeight -gt 19778036 ];then
    ServerIP='patch.iotex.io'
    patchUrl=`curl https://$ServerIP/$tipHeight`
    echo "the patch url: $patchUrl"

    patchFile=$IOTEX_HOME/data/$tipHeight.patch
    curl $patchUrl >$patchFile

    if [ ! -f $patchFile ];then
        echo "$patchFile does not exist"
        exit 1
    fi
fi

echo "download $patchFile success, please upgrade to v1.8.4 and restart iotex-server"
