# lgyos
my own os

### 2016.07.11 ########################
查找loader.bin并加载至内存算法的c语法描
述

/* 常量声明 */
/* 根目录最大条目数是224,每个条目32字节,每个扇区512字节,算出根目录扇区数,
 * 如果结果除不尽,需要商加1,才是最终根目录的扇区数最大值,这里是14 */
#define ROOT_DIR_SECTORS_COUNT 14
/* 函数声明 */
void read_sector(short start_sector, char read_sector_count);

for (int i = 0; i < ROOT_DIR_SECTORS_COUNT; i++) {
}
