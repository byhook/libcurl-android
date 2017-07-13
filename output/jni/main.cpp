#include <curl/curl.h>
#include <iostream>

using namespace std;

int main(int argc,char * argv[])
{
    //定义CURL类型的指针
    CURL * curl;
    //定义CURLcode类型的变量，保存返回状态码
    CURLcode res;

    //初始化一个CURL类型的指针
    curl = curl_easy_init();
    if(curl!=NULL)
    {

        curl_easy_setopt(curl, CURLOPT_URL, argv[1]);        
        //curl_easy_setopt(curl, CURLOPT_WRITEDATA, recv);

        res = curl_easy_perform(curl);
        if(res != CURLE_OK){
             cout << curl_easy_strerror(res) << endl;
    }

        //清除curl操作.
        curl_easy_cleanup(curl);
    }

    return 0;
}
