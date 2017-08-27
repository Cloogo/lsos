#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>

char* peekUntil(int sock,char* sym);

int main(){
    int is=open("hankaku.txt",O_RDONLY);
    char bins[16];
    memset(bins,0,sizeof(bins));
    while(1){
        char* p;
        p=peekUntil(is,"\n");
        free(p);
        p=NULL;
        for(int i=0;i<16;i++){
            p=peekUntil(is,"\n");
            unsigned char bin=0;
            for(int j=0;j<8;j++){
                if(p[j]=='*'){
                    bin|=1<<(7-j);
                }
            }
            printf("%#-04x,",bin);
            free(p);
            p=NULL;
        }
        printf("\n");
        p=peekUntil(is,"\n");
        if(*p=='\0'){
            free(p);
            break;
        }
    }
    close(is);
}

char* peekUntil(int sock,char* sym){
    size_t slen=strlen(sym);
    char buf[slen],*bptr=buf;
    memset(buf,0,slen);
    size_t len=512;
    char* str=malloc(len),*ptr=str;
    memset(str,0,len);
    size_t sz=0;
    while(read(sock,ptr,1)>0){
        sz++;
        *bptr++=*ptr++;
        if(sz>=len){
            str=realloc(str,2*len);
            ptr=str+sz;
            len*=2;
        }
        if(bptr-buf>=slen){
            bptr=buf;
        }
        size_t llen=slen-(bptr-buf);
        size_t rlen=slen-llen;
        if(sz<=slen){
            if(sz!=slen)continue;
            if(strncmp(buf,sym,slen)==0){
                break;
            }
        }else if(strncmp(bptr,sym,llen)==0&&strncmp(buf,sym+llen,rlen)==0){
            break;
        }
    }
    *ptr='\0';
    return str;
}
