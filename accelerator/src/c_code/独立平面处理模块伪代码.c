startAddr = c*deltaH*H*W*2 + h*deltaH*W*2;  

void mergeWidth(){
    for(i=0; i<deltaC; i++){
        readAddrStart = startAddr + 2*w; //就是
        writeAddrStart = startAddr + w; //w>=0
        for(k=0;k<blockNumH; k++){
            for(j=0; j<jointBlockNumW; j++){ // 对于每一行，将jointBlockNumW个结果图Block的在当前行的左右两半部分数据进行收尾合并，
                readAddr0 = readAddrStart + i*deltaH*H*W*2 + k*2*W + j*2 - 1; //第j-1个结果图Block的当前行的右半部分数据
                readAddr1 = readAddr0 + 1 //第j个结果图Block的当前行的左半部分数据
                writeAddr = writeAddrStart + i*deltaH*H*W*2 + k*2*W + j; //预期的合并结果写入地址
                result0 = MEMREAD(readAddr0);
                result1 = MEMREAD(readAddr1);
                MEMWRITE(writeAddr, result0 + result1);
            }
            // 将第jointBlockNumW-1个结果图Block的当前行的右半部分数据直接用作到拼接后结果图的最右一列
            // readAddr0 = readAddrStart + i*deltaH*H*W*2 + k*2*W + jointBlockNumW*2 - 1; //第jointBlockNumW-1个结果图Block的当前行的右半部分数据
            // tmpResult = MEMREAD()
        }
    }
}

void mergeWidth(){
    for(i=0; i<deltaC; i++){
        readAddrStart = startAddr + 2*w; //就是
        writeAddrStart = startAddr + w; //w>=0
        for(k=0;k<blockNumH; k++){
            for(j=0; j<jointBlockNumW; j++){ // 对于每一行，将jointBlockNumW个结果图Block的在当前行的左右两半部分数据进行收尾合并，
                readAddr0 = readAddrStart + i*deltaH*H*W*2 + k*2*W + j*2 - 1; //第j-1个结果图Block的当前行的右半部分数据
                readAddr1 = readAddr0 + 1 //第j个结果图Block的当前行的左半部分数据
                writeAddr = writeAddrStart + i*deltaH*H*W*2 + k*2*W + j; //预期的合并结果写入地址
                result0 = MEMREAD(readAddr0);
                result1 = MEMREAD(readAddr1);
                MEMWRITE(writeAddr, result0 + result1);
            }
            // 将第jointBlockNumW-1个结果图Block的当前行的右半部分数据直接用作到拼接后结果图的最右一列
            // readAddr0 = readAddrStart + i*deltaH*H*W*2 + k*2*W + jointBlockNumW*2 - 1; //第jointBlockNumW-1个结果图Block的当前行的右半部分数据
            // tmpResult = MEMREAD()
        }
    }
}

