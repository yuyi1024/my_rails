require "digest"
require "uri"
require "net/http"
require "net/https"
require "json"
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

	class ECpayPaymentClient
    include ECpayErrorDefinition

		def initialize
      @helper = APIHelper.new
      @verify_aiochkout = ECpayPayment::AioCheckOutParamVerify.new

    end

    def aio_check_out_all(params:, invoice:{})
      unsupport = []
      aiochkout_base_proc!(params: params, invoice: invoice, unsupport_param: unsupport, pay_method: 'ALL')
      # handle Ignore Payment
      params['IgnorePayment'] = @helper.get_ignore_pay.join('#')
      html = aiochkout_pos_proc!(params: params)
      return html

    end

    def aio_check_out_credit_onetime(params:, invoice:{})
      unsupport = ['HoldTradeAMT', 'IgnorePayment']
      aiochkout_base_proc!(params: params, invoice: invoice, unsupport_param: unsupport, pay_method: 'Credit')
      html = aiochkout_pos_proc!(params: params)
      return html
    end

    def aio_check_out_googlepay(params:, invoice:{})
      unsupport = ['HoldTradeAMT', 'IgnorePayment']
      aiochkout_base_proc!(params: params, invoice: invoice, unsupport_param: unsupport, pay_method: 'GooglePay')
      html = aiochkout_pos_proc!(params: params)
      return html
    end

    def aio_check_out_credit_divide(params:, invoice:{}, installment: , amount: )
      unsupport = ['HoldTradeAMT', 'IgnorePayment', 'Redeem', 'PeriodAmount', 'PeriodType', 'Frequency', 'ExecTimes', 'PeriodReturnURL']
      aiochkout_base_proc!(params: params, invoice: invoice, unsupport_param: unsupport, pay_method: 'Credit')
      params['CreditInstallment'] = installment
      if params['TotalAmount'].to_i != amount.to_i
        params['InstallmentAmount'] = amount
      end
      html = aiochkout_pos_proc!(params: params)
      return html
    end

    def aio_check_out_credit_period(period_info:, params:, invoice:{})
      # 'PeriodAmount', 'PeriodType', 'Frequency', 'ExecTimes', 'PeriodReturnURL'
      unsupport = ['HoldTradeAMT', 'IgnorePayment', 'Redeem', 'CreditInstallment', 'InstallmentAmount']
      aiochkout_base_proc!(params: params, invoice: invoice, unsupport_param: unsupport, pay_method: 'Credit')
      if period_info.is_a?(Hash)
        period_args = ['PeriodAmount', 'PeriodType', 'Frequency', 'ExecTimes', 'PeriodReturnURL']
        if period_info.keys.sort() == period_args.sort()
          params.merge!(period_info)
          # Add total amount protection!!!

          html = aiochkout_pos_proc!(params: params)
          return html
        else
          raise "Credit card period parameters must be #{period_args}."
        end
      else
        raise "Recieved period_info argument must be a Hash."
      end

    end

    def aio_check_out_atm(params:, url_return_payinfo:'', exp_period:'', client_redirect:'', invoice:{})
      unsupport = ['IgnorePayment']
      aiochkout_base_proc!(params: params, invoice: invoice, unsupport_param: unsupport, pay_method: 'ATM')
      if exp_period == ''
        params.delete('ExpireDate')
      else
        params['ExpireDate'] = exp_period
      end
			if client_redirect == ''
        params.delete('ClientRedirectURL')
			else
				params['ClientRedirectURL'] = client_redirect
      end
			if url_return_payinfo == ''
        params.delete('PaymentInfoURL')
			else
				params['PaymentInfoURL'] = url_return_payinfo
      end
      html = aiochkout_pos_proc!(params: params)
      return html
    end

    def aio_check_out_webatm(params:, invoice:{})
      unsupport = ['IgnorePayment']
      aiochkout_base_proc!(params: params, invoice: invoice, unsupport_param: unsupport, pay_method: 'WebATM')
      html = aiochkout_pos_proc!(params: params)
      return html
    end

    def aio_check_out_cvs(cvs_info:, params:, invoice:{}, client_redirect_url:'')
      unsupport = ['IgnorePayment']
      aiochkout_base_proc!(params: params, invoice: invoice, unsupport_param: unsupport, pay_method: 'CVS')
      if cvs_info.is_a?(Hash)
        cvs_args = ['StoreExpireDate', 'Desc_1', 'Desc_2', 'Desc_3', 'Desc_4', 'PaymentInfoURL']
        if cvs_info.keys.sort() == cvs_args.sort()
          params.merge!(cvs_info)
          if client_redirect_url == '' or client_redirect_url.nil?
            params.delete('ClientRedirectURL')
          else
            params['ClientRedirectURL'] = client_redirect_url
          end
          html = aiochkout_pos_proc!(params: params)
          return html
        else
          raise "CVS info keys must match #{cvs_args}."
        end
      else
        raise "Recieved cvs_info argument must be a Hash."
      end
    end

		def aio_check_out_barcode(barcode_info:, params:, invoice:{}, client_redirect_url:'')
      unsupport = ['IgnorePayment']
      aiochkout_base_proc!(params: params, invoice: invoice, unsupport_param: unsupport, pay_method: 'BARCODE')
      if barcode_info.is_a?(Hash)
        barcode_args = ['StoreExpireDate', 'Desc_1', 'Desc_2', 'Desc_3', 'Desc_4', 'PaymentInfoURL']
        if barcode_info.keys.sort() == barcode_args.sort()
          params.merge!(barcode_info)
          if client_redirect_url == '' or client_redirect_url.nil?
            params.delete('ClientRedirectURL')
          else
            params['ClientRedirectURL'] = client_redirect_url
          end
          html = aiochkout_pos_proc!(params: params)
          return html
        else
          raise "BARCODE info keys must match #{barcode_args}."
        end
      else
        raise "Recieved barcode_info argument must be a Hash."
      end
    end

    ### Private method definition start ###
    private
      def aiochkout_base_proc!(params:, invoice:{}, unsupport_param:, pay_method:)
        if params.is_a?(Hash)
          # Transform param key to string
          params.stringify_keys()
          # Remove HoldTradeAMT, IgnorePayment
          if unsupport_param.is_a?(Array)
            unsupport_param.each{|pa|params.delete(pa)}
          else
            raise "argument unsupport_param must be an Array."
          end
          # User doesn't have to specify ChoosePayment
          params['ChoosePayment'] = pay_method
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
          # InvoiceMark based on keyword argument: invoice
          if invoice == {}
            params['InvoiceMark'] = 'N'
          else
            params['InvoiceMark'] = 'Y'
            @verify_aiochkout.verify_aio_inv_param(invoice)
            #merge param & inv param
            params.merge!(invoice)
          end
        else
          raise ECpayInvalidParam, "Recieved parameter object must be a Hash"
        end
      end

      def aiochkout_pos_proc!(params:)
        @verify_aiochkout.verify_aio_payment_param(params)
        #encode special param
        sp_param = @verify_aiochkout.get_special_encode_param('AioCheckOut')
        @helper.encode_special_param!(params, sp_param)

        # Insert chkmacval
        chkmac = @helper.gen_chk_mac_value(params)
        params['CheckMacValue'] = chkmac
        # gen post html
        api_url = @verify_aiochkout.get_svc_url('AioCheckOut', @helper.get_op_mode)
        htm = @helper.gen_html_post_form(act: api_url, id: '_form_aiochk', parameters: params)
        # return  post htm
        return htm
      end
    ### Private method definition end ###

  end
end
