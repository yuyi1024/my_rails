require "digest"
require "uri"
require "net/http"
require "net/https"
require "json"
require "date"
require "ecpay_logistics/helper"
require "ecpay_logistics/verification"
require "ecpay_logistics/error"
require "ecpay_logistics/core_ext/hash"
require "ecpay_logistics/core_ext/string"
# require "../../../gem/lib/ecpay_logistics/helper"
# require "../../../gem/lib/ecpay_logistics/verification"
# require "../../../gem/lib/ecpay_logistics/error"
# require "../../../gem/lib/ecpay_logistics/core_ext/hash"
# require "../../../gem/lib/ecpay_logistics/core_ext/string"

module ECpayLogistics

    class QueryClient

        def initialize
            @helper = ECpayLogistics::APIHelper.new
        end

        def expressmap(param)
            query_base_proc!(params: param)
            param.delete('PlatformID')
            res = query_pos_proc!(params: param, apiname: 'Map')
            return res
        end

        def updateshipmentinfo(param)
            query_base_proc!(params: param)
            res = query_pos_proc!(params: param, apiname: 'UpdateShipmentInfo')
            return res
        end

        def querylogisticstradeinfo(param)
            query_base_proc!(params: param)
            unix_time = get_curr_unix_time() + 120
            param['TimeStamp'] = unix_time.to_s
            p param['TimeStamp']
            res = query_pos_proc!(params: param, apiname: 'QueryLogisticsTradeInfo')
            return res
        end

        def printtradedocument(param)
            query_base_proc!(params: param)
            res = query_pos_proc!(params: param, apiname: 'printTradeDocument')
            return res
        end

        def logisticscheckaccounts(param)
            query_base_proc!(params: param)
            res = query_pos_proc!(params: param, apiname: 'LogisticsCheckAccounts')
            return res
        end

        def createtestdata(param)
            query_base_proc!(params: param)
            res = query_pos_proc!(params: param, apiname: 'CreateTestData')
            return res
        end

        ### Private method definition start ###
        private

            def get_curr_unix_time()
                return Time.now.to_i
            end

            def query_base_proc!(params:)
                if params.is_a?(Hash)
                    # Transform param key to string
                    params.stringify_keys()

                    # Process PlatformID & MerchantID by contractor setting
    			          if @helper.is_contractor?
    			            params['PlatformID'] = @helper.get_mercid
    			            if params['MerchantID'].nil?
    			              raise "[MerchantID] should be specified when you're contractor-Platform."
    			            end
    			          else
    			            params['PlatformID'] = ''
    			            params['MerchantID'] = @helper.get_mercid
    			          end

                else
                    raise ECpayInvalidParam, "Recieved parameter object must be a Hash"
                end
            end

            def query_pos_proc!(params:, apiname:)
                verify_query_api = ECpayLogistics::QueryParamVerify.new(apiname)
    						if apiname == 'Map'
    							verify_query_api.verify_query_param(params)
    						elsif apiname == 'UpdateShipmentInfo'
    							verify_query_api.verify_updateshipmentinfo_param(params)
    						elsif apiname == 'QueryLogisticsTradeInfo'
    							verify_query_api.verify_query_param(params)
    						elsif apiname == 'printTradeDocument'
    							verify_query_api.verify_query_param(params)
                elsif apiname == 'LogisticsCheckAccounts'
    							verify_query_api.verify_query_param(params)
                elsif apiname == 'CreateTestData'
    							verify_query_api.verify_query_param(params)
    						end
                #encode special param
                sp_param = verify_query_api.get_special_encode_param(apiname)
                @helper.encode_special_param!(params, sp_param)
                # Insert chkmacval
                chkmac = @helper.gen_chk_mac_value(params, mode: 0)
                params['CheckMacValue'] = chkmac
                p params
                # gen post html
                api_url = verify_query_api.get_svc_url(apiname, @helper.get_op_mode)
                #post from server
                if apiname == 'Map' or apiname == 'printTradeDocument'
                  resp = @helper.gen_html_post_form(act: api_url, id: '_form_map', parameters: params)
                else
                  resp = @helper.http_request(method: 'POST', url: api_url, payload: params)
                end

                # return  post response
                return resp
            end
        ### Private method definition end ###

    end
end
