#!/bin/bash
TOKEN="773953821:AAF17idyy1y8yHZ7yA7dNnli-3dCpbMWdQU"
CHAT_ID="751524701"
MENSAJE="⚠️ El backup falló el $(date)"
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id=$CHAT_ID -d text="$MENSAJE"
