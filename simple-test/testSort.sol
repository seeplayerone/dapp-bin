pragma solidity 0.4.25;

contract SortGasTest {
    
    function testQuickSortMemory() public returns(uint[]) {
        uint[] memory data = new uint[](19);
        data[0] = 4;
        data[1] = 15;
        data[2] = 8;
        data[3] = 11;
        data[4] = 3;
        data[5] = 17;
        data[6] = 6;
        data[7] = 19;
        data[8] = 2;
        data[9] = 10;
        data[10] = 14;
        data[11] = 5;
        data[12] = 18;
        data[13] = 1;
        data[14] = 13;
        data[15] = 7;
        data[16] = 16;
        data[17] = 9;
        data[18] = 12;

        quickSortMemory(data, int(0), int(data.length - 1));
        return data;
    }

    function testQuickSortStorage() public returns(uint[]) {
        uint[] storage data;
        data.push(4);
        data.push(15);
        data.push(8);
        data.push(11);
        data.push(3);
        data.push(17);
        data.push(6);
        data.push(19);
        data.push(2);
        data.push(10);
        data.push(14);
        data.push(5);
        data.push(18);
        data.push(1);
        data.push(13);
        data.push(7);
        data.push(16);
        data.push(9);
        data.push(12);
         
       quickSortStorage(data, int(0), int(data.length - 1));
       return data;
    }

    function testBubbleSortMemory() public returns(uint[]) {

        uint[] memory data = new uint[](19);
        data[0] = 4;
        data[1] = 15;
        data[2] = 8;
        data[3] = 11;
        data[4] = 3;
        data[5] = 17;
        data[6] = 6;
        data[7] = 19;
        data[8] = 2;
        data[9] = 10;
        data[10] = 14;
        data[11] = 5;
        data[12] = 18;
        data[13] = 1;
        data[14] = 13;
        data[15] = 7;
        data[16] = 16;
        data[17] = 9;
        data[18] = 12;         
       bubbleSortMemory(data);
       return data;
    }

    function testBubbleSortStorage() public returns(uint[]) {
        uint[] storage data;
        data.push(4);
        data.push(15);
        data.push(8);
        data.push(11);
        data.push(3);
        data.push(17);
        data.push(6);
        data.push(19);
        data.push(2);
        data.push(10);
        data.push(14);
        data.push(5);
        data.push(18);
        data.push(1);
        data.push(13);
        data.push(7);
        data.push(16);
        data.push(9);
        data.push(12);
         
       bubbleSortStorage(data);
       return data;
    }

    function quickSortMemory(uint[] memory arr, int left, int right) internal{
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSortMemory(arr, left, j);
        if (i < right)
            quickSortMemory(arr, i, right);
    }

   function quickSortStorage(uint[] storage arr, int left, int right) internal{
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSortStorage(arr, left, j);
        if (i < right)
            quickSortStorage(arr, i, right);
    }

    function bubbleSortMemory(uint[] memory values) internal {
        uint length = values.length;
        for (uint i = 0; i < length - 1; i ++) {
            for (uint j = 0; j < length - i - 1; j ++) {
                if(values[j] > values[j+1]) {
                    (values[j], values[j+1]) = (values[j+1], values[j]);
                }
            }
        }
    }

    function bubbleSortStorage(uint[] storage values) internal {
        uint length = values.length;
        for (uint i = 0; i < length - 1; i ++) {
            for (uint j = 0; j < length - i - 1; j ++) {
                if(values[j] > values[j+1]) {
                    (values[j], values[j+1]) = (values[j+1], values[j]);
                }
            }
        }
    }
}