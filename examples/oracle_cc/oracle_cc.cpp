#include "shim.h"
#include "logging.h"
#include <string>

#define OK "OK"
#define ASSET_PRICE "getPrice"
#define ASSET_IoT "getIotData"
#define ASSET_InterChain "getInterChain"
#define ASSET_RANDOM "getRandom"  
// #define NOT_FOUND "ERR.Asset not found"
// #define ERR_RETRIEVE "ERR.Retrieved value is not String"
#define MAX_VALUE_SIZE 1024
#define MAX_RANDOM_SIZE 32

char const hex[16] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B','C','D','E','F'};

void toHex(uint8_t* dst, uint8_t* src, int length) {
  int i,j;
  for (i = 0; i < length; ++i) {
    const uint8_t ch = src[i];
    j = i*2;
    dst[j] = (uint8_t)hex[(ch  & 0xF0) >> 4];
    dst[j + 1] = (uint8_t)hex[(ch  & 0xF)];
  }
}

// implements chaincode logic for init
int init(
    uint8_t* response,
    uint32_t max_response_len,
    uint32_t* actual_response_len,
    shim_ctx_ptr_t ctx)
{
    return 0;
}

//  Add asset_name, value to ledger
std::string storeAsset(std::string asset_name, std::string value, shim_ctx_ptr_t ctx)
{
    LOG_DEBUG("DemoCC: +++ storeAsset +++");

    put_state(asset_name.c_str(), (uint8_t*)value.c_str(), (uint32_t)value.length() + 1, ctx);

    return OK;
}

int retrieveAsset(std::string asset_name, std::string& value, shim_ctx_ptr_t ctx)
{
    LOG_DEBUG("DemoCC: +++ retrieveAsset +++");
    int result = 0;
    uint32_t asset_bytes_len = 0;
    uint8_t asset_bytes[MAX_VALUE_SIZE];
    if (asset_name == ASSET_RANDOM){
        uint8_t random_bytes[MAX_RANDOM_SIZE+1];
         
        if (get_random_bytes(random_bytes, MAX_RANDOM_SIZE) == 0)
        {
           toHex(asset_bytes, random_bytes, MAX_RANDOM_SIZE); 
           // ADD null char
           asset_bytes[MAX_RANDOM_SIZE*2] = '\0';
           asset_bytes_len = MAX_RANDOM_SIZE*2 + 1;
        }
    }else{
        get_state(asset_name.c_str(), asset_bytes, sizeof(asset_bytes), &asset_bytes_len, ctx);
    }

    //  check if asset_name exists
    if (asset_bytes_len > 0)
    {
        if (asset_bytes[asset_bytes_len - 1] != '\0')
        {
            result = -1;
        } else {
            value.assign((char*)(asset_bytes));
        }
    } else {
        //  asset does not exist
        result = -2;
    }

    return result;
}

// implements chaincode logic for invoke
int invoke(
    uint8_t* response,
    uint32_t max_response_len,
    uint32_t* actual_response_len,
    shim_ctx_ptr_t ctx)
{
    LOG_DEBUG("DemoCC: +++ Executing democc chaincode invocation +++");

    std::string function_name;
    std::vector<std::string> params;
    get_func_and_params(function_name, params, ctx);
    std::string asset_name = params[0];
    std::string result;
    int get_result = 0;
    if (function_name == "storeAsset")
    {
        std::string value = params[1];
        result = storeAsset(asset_name, value, ctx);
    }
    else if (function_name == "retrieveAsset")
    {
        get_result = retrieveAsset(asset_name, result, ctx);
        if (get_result != 0)
        {
            LOG_DEBUG("DemoCC: retrieve Fail");
            *actual_response_len = 0;
            return -1;    
        }
    }
    else
    {
        // unknown function
        LOG_DEBUG("DemoCC: RECEIVED UNKNOWN transaction '%s'", function_name);
        return -1;
    }

    // check that result fits into response
    int neededSize = result.size();
    if (max_response_len < neededSize)
    {
        // error:  buffer too small for the response to be sent
        LOG_DEBUG("DemoCC: Response buffer too small");
        *actual_response_len = 0;
        return -1;
    }

    // copy result to response
    memcpy(response, result.c_str(), neededSize);
    *actual_response_len = neededSize;
    LOG_DEBUG("DemoCC: Response: %s", result.c_str());
    LOG_DEBUG("DemoCC: +++ Executing done +++");
    return 0;
}