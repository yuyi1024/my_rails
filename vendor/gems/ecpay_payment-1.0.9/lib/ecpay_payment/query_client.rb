require "digest"
require "uri"
require "net/http"
require "net/https"
require "json"
require "date"
require "ecpay_payment/helper"
require "ecpay_payment/verification"
require "ecpay_payment/error"
require "ecpay_payment/core_ext/hash"
require "ecpay_payment/core_ext/string"
# require "../../../gem/lib/ecpay_payment/helper"
# require "../../../gem/lib/ecpay_payment/verification"
# require "../../../gem/lib/ecpay_payment/error"
# require "../../../gem/lib/ecpay_payment/core_ext/hash"
# require "../../../gem/lib/ecpay_payment/core_ext/string"

module ECpayPayment

  class ECpayQueryClient

    def initialize
      @helper = APIHelper.new
      #@verify_query_api = QueryTradeInfoParamVerify.new

    end

    def create_server_order(param)
      query_base_proc!(params: param)
      res = query_pos_proc!(params: param, apiname: 'CreateServerOrder')
      return res
    end

    def query_trade_info(param)
      query_base_proc!(params: param)
      unix_time = get_curr_unix_time() + 120
      param['TimeStamp'] = unix_time.to_s
      p param['TimeStamp']
      res = query_pos_proc!(params: param, apiname: 'QueryTradeInfo')
      return res
    end

    def query_credit_period(param)
      query_base_proc!(params: param)
      unix_time = get_curr_unix_time() + 120
      param['TimeStamp'] = unix_time.to_s
      p param['TimeStamp']
      param.delete('PlatformID')
      res = query_pos_proc!(params: param, apiname: 'QueryCreditCardPeriodInfo')
      return res
    end

    def query_transac_csv(param)
      query_base_proc!(params: param)
      param.delete('PlatformID')
      res = query_pos_proc!(params: param, apiname: 'TradeNoAio', big5_trans: true)
      return res
    end

    def query_credit_single(param)
      query_base_proc!(params: param)
      param.delete('PlatformID')
      res = query_pos_proc!(params: param, apiname: 'QueryTradeV2')
      return res
    end

    def query_credit_csv(param)
      query_base_proc!(params: param)
      param.delete('PlatformID')
      res = query_pos_proc!(params: param, apiname: 'FundingReconDetail')
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

      def query_pos_proc!(params:, apiname:, big5_trans:false)
        verify_query_api = ECpayPayment::QueryParamVerify.new(apiname)
        verify_query_api.verify_query_param(params)
        if apiname == 'CreateServerOrder'
          exclusive_list = ['PaymentToken']
        else
          exclusive_list = []
        end
        #encode special param
        # for PaymentToken
        exclusive_ele = {}
        for param in exclusive_list
          exclusive_ele[param] = params[param]
          params.delete(param)
        end
        # Insert chkmacval
        chkmac = @helper.gen_chk_mac_value(params)
        params['CheckMacValue'] = chkmac

        for param in exclusive_list
          paymenttoken = @helper.gen_aes_encrypt(exclusive_ele)
          params[param] = paymenttoken
        end

        # gen post html
        api_url = verify_query_api.get_svc_url(apiname, @helper.get_op_mode)
        p params
        #post from server
        resp = @helper.http_request(method: 'POST', url: api_url, payload: params)

        # return  post response
        if big5_trans
          return resp.encode('utf-8', 'big5')
        else
          return resp
        end
      end
    ### Private method definition end ###

  end
end
