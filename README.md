# lgyos
my own os

### 2016.07.11 ########################
查找loader.bin并加载至内存算法的c语法描
述

/* 常量声明 */
/* 根目录最大条目数是224,每个条目32字节,每个扇区512字节,算出根目录扇区数,
 * 如果结果除不尽,需要商加1,才是最终根目录的扇区数最大值,这里是14 */
#define ROOT_DIR_SECTORS_COUNT 14
#define ROOT_DIR_START_SECTOR  19
/* 函数声明 */
void read_sector(short start_sector, char read_sector_count);
/* 参数: 要查找的文件名
 * 返回值: 文件内容开始的簇号 */
short find_file(char *filename);
void load_file(from, to);
void to_uppercase(string s);

for (int i = 0; i < ROOT_DIR_SECTORS_COUNT; i++) {
    read_sector(ROOT_DIR_START_SECTOR, 1);
    if (find_file("loader.bin")) {
        load_file(from, to)
        break;
    }
}

if (i == ROOT_DIR_SECTORS_COUNT)
    printf("loader.bin没找到");


============== find_file() ===========================
short find_file(char *filename)
{
    format(filename);
    /* 查找文件名代码 */
}

============= format() ===============================
void format(char *s)
{
    to_uppercase(s);
    to_fat12_style(s);
}
