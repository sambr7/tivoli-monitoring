######################################################################
# ScriptName: settivoli.sh
# Author: Samuel Januario (samuel.januario01@gmail)
# Date: 25/07/2017
# Purpose: Script to set ITM 6 Environment variables
######################################################################
#!/usr/bin/bash

# Input variable
candle=$1

if [ "0$candle" != 0 ]
  then
    case $candle in
      "TEPS")
      echo "Setting up CANDLEHOME variable for $candle..."
      CANDLEHOME=/opt/IBM/ITM_TPS
      export CANDLEHOME
      export PATH=$PATH:$CANDLEHOME/bin
      sleep 1
      echo "Done."
      ;;
      "RTEMS")
      echo "Setting up CANDLEHOME variable for $candle..."
      CANDLEHOME=/opt/IBM/ITM_RMS
      export CANDLEHOME
      export PATH=$PATH:$CANDLEHOME/bin
      sleep 1
      echo "Done."
      ;;
      "HUBTEMS")
      echo "Setting up CANDLEHOME variable for $candle..."
      CANDLEHOME=/opt/IBM/ITM_HMS
      export CANDLEHOME
      export PATH=$PATH:$CANDLEHOME/bin
      sleep 1
      echo "Done."
      ;;
      "AGENT")
      echo "Setting up CANDLEHOME variable for $candle..."
      CANDLEHOME=/opt/IBM/ITM
      export CANDLEHOME
      export PATH=$PATH:$CANDLEHOME/bin
      sleep 1
      echo "Done."
      ;;
    esac
else
    echo "Usage: settivoli <Environment|Component>"
    echo "Possible options: TEPS|HUBTEMS|RTEMS|AGENT"
    echo "Example: settivoli HUBTEMS"
fi
