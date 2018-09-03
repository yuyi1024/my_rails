# require "../../../gem/lib/ecpay_payment/error"
require "ecpay_payment/error"
require "nokogiri"
require 'date'

module ECpayPayment
  class PaymentVerifyBase
    include ECpayErrorDefinition
    @@param_xml = Nokogiri::XML(File.open(File.join(File.dirname(__FILE__), 'ECpayPayment.xml')))

    def get_svc_url(apiname, mode)
      url = @@param_xml.xpath("/ECPayPayment/#{apiname}/ServiceAddress/url[@type=\"#{mode}\"]").text
      return url
    end

    def get_special_encode_param(apiname)
      ret = []
      node = @@param_xml.xpath("/ECPayPayment/#{apiname}/Parameters//param[@urlencode=\"1\"]")
      node.each {|elem| ret.push(elem.attributes['name'].value)}
      return ret
    end

    def get_basic_params(apiname)
      basic_param = []
      @@param_xml.xpath("/ECPayPayment/#{apiname}/Parameters/param[@require=\"1\"]").each do |elem|
        basic_param.push(elem.attributes['name'].value)
      end
      return basic_param
    end

    def get_cond_param(apiname)
      aio_sw_param = []
      conditional_param = {}
      @@param_xml.xpath("/ECPayPayment/#{apiname}/Config/switchparam/n").each do |elem|
        aio_sw_param.push(elem.text)
      end
      aio_sw_param.each do |pname|
        opt_param = {}
        node = @@param_xml.xpath("/ECPayPayment/#{apiname}/Parameters//param[@name=\"#{pname}\"]")
        node.xpath('./condparam').each do |elem|
          opt = elem.attributes['owner'].value
          params = []
          elem.xpath('./param[@require="1"]').each do |pa|
            params.push(pa.attributes['name'].value)
          end
          opt_param[opt] = params
        end
        conditional_param[pname] = opt_param
      end
      return conditional_param
    end

    def get_param_type(apiname)
      param_type = {}
      @@param_xml.xpath("/ECPayPayment/#{apiname}/Parameters//param").each do |elem|
        param_type[elem.attributes['name'].value] = elem.attributes['type'].value
      end
      return param_type
    end

    def get_opt_param_pattern(apiname)
      pattern = {}
      node = @@param_xml.xpath("/ECPayPayment/#{apiname}/Parameters//param[@type=\"Opt\"]")
      node.each do |param_elem|
        opt_elems = param_elem.xpath('./option')
        opt = []
        opt_elems.each{|oe|opt.push(oe.text)}
        pattern[param_elem.attributes['name'].value] = opt
      end
      return pattern
    end

    def get_int_param_pattern(apiname)
      pattern = {}
      node = @@param_xml.xpath("/ECPayPayment/#{apiname}/Parameters//param[@type=\"Int\"]")
      node.each do |param_elem|
        mode = param_elem.xpath('./mode').text
        mx = param_elem.xpath('./maximum').text
        mn = param_elem.xpath('./minimal').text
        a = []
        [mode, mx, mn].each{|f|a.push(f)}
        pattern[param_elem.attributes['name'].value] = a
      end
      return pattern
    end

    def get_str_param_pattern(apiname)
      pattern = {}
      node = @@param_xml.xpath("/ECPayPayment/#{apiname}/Parameters//param[@type=\"String\"]")
      node.each do |param_elem|
        p_name = param_elem.attributes['name'].value
        pat_elems = param_elem.xpath('./pattern')
        # if pat_elems.length > 1
        #   raise "Only 1 pattern tag is allowed for each parameter (#{p_name}) "
        # elsif pat_elems.length = 0
        #   raise "No pattern tag found for parameter (#{p_name}) "
        # end
        pat = pat_elems.text
        pattern[p_name] = pat
      end
      return pattern
    end

    def get_depopt_param_pattern(apiname)
      pattern = {}

      node = @@param_xml.xpath("/ECPayPayment/#{apiname}/Parameters//param[@type=\"DepOpt\"]")
      node.each do |param_elem|
        parent_n_opts = {}
        sub_opts = {}
        p_name = param_elem.attributes['name'].value
        parent_name = param_elem.attributes['main'].value
        param_elem.xpath('./mainoption').each do |elem|
          k = elem.attributes['name'].value
          opt = []
          elem.element_children.each{|c|opt.push(c.text)}
          sub_opts[k] = opt
        end
        parent_n_opts[parent_name] = sub_opts
        pattern[p_name] = parent_n_opts
      end
      return pattern
    end

    def get_all_pattern(apiname)
      res = {}
      res['Type_idx'] = self.get_param_type(apiname)
      res['Int'] = self.get_int_param_pattern(apiname)
      res['String'] = self.get_str_param_pattern(apiname)
      res['Opt'] = self.get_opt_param_pattern(apiname)
      res['DepOpt'] = self.get_depopt_param_pattern(apiname)
      return res
    end

    def verify_param_by_pattern(params, pattern)
      type_index = pattern['Type_idx']
      params.keys.each do |p_name|
        p_type = type_index[p_name]
        patt_container = pattern[p_type]
        case
        when p_type == 'String'
          regex_patt = patt_container[p_name]
          mat = /#{regex_patt}/.match(params[p_name])
          if mat.nil?
            raise ECpayInvalidParam, "Wrong format of param #{p_name} or length exceeded."
          end
        when p_type == 'Opt'
          aval_opt = patt_container[p_name]
          mat = aval_opt.include?(params[p_name])
          if mat == false
            raise ECpayInvalidParam, "Unexpected option of param #{p_name} (#{params[p_name]}). Avaliable option: (#{aval_opt})."
          end
        when p_type == 'Int'
          criteria = patt_container[p_name]
          mode = criteria[0]
          max = criteria[1].to_i
          min = criteria[2].to_i
          val = params[p_name].to_i
          case
          when mode == 'BETWEEN'
            if val < min or val > max
              raise ECpayInvalidParam, "Value of #{p_name} should be between #{min} and #{max} ."
            end
          when mode == 'GE'
            if val < min
              raise ECpayInvalidParam, "Value of #{p_name} should be greater than or equal to #{min}."
            end
          when mode == 'LE'
            if val > max
              raise ECpayInvalidParam, "Value of #{p_name} should be less than or equal to #{max}."
            end
          when mode == 'EXCLUDE'
            if val >= min and val <= max
              raise ECpayInvalidParam, "Value of #{p_name} can NOT be between #{min} and #{max} .."
            end
          else
            raise "Unexpected integer verification mode for parameter #{p_name}: #{mode}. "
          end
        when p_type == 'DepOpt'
          dep_opt = patt_container[p_name]
          parent_param = dep_opt.keys()[0]
          all_dep_opt = dep_opt[parent_param]
          parent_val = params[parent_param]
          aval_opt = all_dep_opt[parent_val]
          if aval_opt.nil? and pattern['Opt'][parent_param].include?(parent_val) == false
            raise  ECpayInvalidParam, "Cannot find avaliable option of [#{p_name}] by related param [#{parent_param}](Value: #{parent_val})."
          elsif aval_opt.is_a?(Array)
            unless aval_opt.include?(params[p_name])
              raise ECpayInvalidParam, "Unexpected option of param #{p_name} (#{params[p_name]}). Avaliable option: (#{aval_opt})."
            end
          end

        else
          raise "Unexpected type (#{p_type}) for parameter #{p_name}. "

        end
      end
    end
  end

  class AioCheckOutParamVerify < PaymentVerifyBase
    include ECpayErrorDefinition
    def initialize
      @aio_basic_param = self.get_basic_params('AioCheckOut').freeze
      @aio_conditional_param = self.get_cond_param('AioCheckOut').freeze
      @all_param_pattern = self.get_all_pattern('AioCheckOut').freeze
    end

    def get_serialized_data
      p @aio_basic_param
      p '---'
      p @aio_conditional_param
      new_di = @aio_conditional_param
      new_di.delete('InvoiceMark')
      p @aio_conditional_param
      p '-----'
      p new_di
      #return @aio_conditional_param['InvoiceMark']['Y']
      #p @@param_xml
    end

    def verify_aio_payment_param(params)
      if params.is_a?(Hash)
        #Force specify : DeviceSource, IgnorePayment, PlatformID EncryptType
        fix_params = {
          'DeviceSource' => '',
          #'PlatformID' => '',
          'EncryptType' => '1',
          'PaymentType' => 'aio'
        }
        params.merge!(fix_params)
        #Verify Basic param requirement
        # if param == {}
        #   raise ECpayInvalidParam, %Q{Parameter hash is empty.}
        # end
        param_diff = @aio_basic_param - params.keys
        unless param_diff == []
          raise ECpayInvalidParam, "Lack required param #{param_diff}"
        end

        # Verify Extend param requirement
        ext_param = @aio_conditional_param.dup
        ext_param.delete('InvoiceMark')
        ext_param.keys.each do |pa|
          val = params[pa]
          related_require_param = ext_param[pa][val]
          if related_require_param.nil? == false and related_require_param != []
            related_require_param.each do |e|
              unless params.keys.include?(e)
                raise ECpayInvalidParam, "Lack required parameter [#{e}] when [#{pa}] is set to [#{val}] "
              end
            end
          end
        end

        #Verify Value pattern of each param
        self.verify_param_by_pattern(params, @all_param_pattern)

      else
        raise TypeError, "Recieved argument is not a hash"
      end

    end

    def verify_aio_inv_param(params)
      if params.is_a?(Hash)
        #發票所有參數預設要全帶

        if params.has_value?(nil)
          raise ECpayInvalidParam, %Q{Parameter value cannot be nil}
        end
        #1. 比對欄位是否缺乏
        inv_param_names = @aio_conditional_param['InvoiceMark']['Y']
        param_diff = inv_param_names - params.keys()
        unless param_diff == []
          raise ECpayInvalidParam, %Q{Lack required invoice param #{param_diff}}
        end
        unexp_param = params.keys() - inv_param_names
        unless unexp_param == []
          raise ECpayInvalidParam, %Q{Unexpected parameter in Invoice parameters #{unexp_param}}
        end

        #2. 比對特殊欄位值相依需求

        #a [CarruerType]為 1 => CustomerID 不能為空
        if params['CarruerType'].to_s == '1'
          if params['CustomerID'].to_s.empty?
            raise ECpayInvoiceRuleViolate, "[CustomerID] can not be empty when [CarruerType] is 1."
          end
        # [CustomerID]不為空 => CarruerType 不能為空
        elsif params['CarruerType'].to_s == ''
            unless params['CustomerID'].to_s.empty?
                raise ECpayInvoiceRuleViolate, "[CarruerType] can not be empty when [CustomerID] is not empty."
            end
        end
        #b 列印註記[Print]為 1 => CustomerName, CustomerAddr
        if params['Print'].to_s == '1'
          if params['CustomerName'].to_s.empty? or params['CustomerAddr'].to_s.empty?
            raise ECpayInvoiceRuleViolate, "[CustomerName] and [CustomerAddr] can not be empty when [Print] is 1."
          end
          unless params['CustomerID'].to_s.empty?
            raise ECpayInvoiceRuleViolate, "[Print] can not be '1' when [CustomerID] is not empty."
          end
        end
        #c CustomerPhone和CustomerEmail至少一個有值
        if  params['CustomerPhone'].to_s.empty? and params['CustomerEmail'].to_s.empty?
          raise ECpayInvoiceRuleViolate, "[CustomerPhone] and [CustomerEmail] can not both be empty."
        end
        #d 別[TaxType]為 2 => ClearanceMark = 1 or 2
        if params['TaxType'].to_s == '2'
          unless ['1', '2'].include?(params['ClearanceMark'].to_s)
            raise ECpayInvoiceRuleViolate, "[ClearanceMark] has to be 1 or 2 when [TaxType] is 2."
          end
        end
        #e 統一編號[CustomerIdentifier]有值時 => CarruerType != 1 or 2, *Donation = 0, Print = 1
        # 統一編號為空值時剔除該欄位
        #if params['CustomerIdentifier'].to_s.empty?
        	#params.delete('CustomerIdentifier')
        #else
        unless params['CustomerIdentifier'].to_s.empty?
          if ['1', '2'].include?(params['CarruerType'].to_s)
            raise ECpayInvoiceRuleViolate, "[CarruerType] Cannot be 1 or 2 when [CustomerIdentifier] is given."
          end
          unless params['Donation'].to_s == '2' and params['Print'].to_s == '1'
            raise ECpayInvoiceRuleViolate, "[Print] must be 1 and [Donation] must be 2 when [CustomerIdentifier] is given."
          end
        end

        # [CarruerType]為'' or 1 時 => CarruerNum = '', [CarruerType]為 2， CarruerNum = 固定長度為 16 且格式為 2 碼大小寫字母加上 14 碼數字。 [CarruerType]為 3 ，帶固定長度為 8 且格式為 1 碼斜線「/」加上由 7 碼數字及大小寫字母組成
        if ['', '1'].include?(params['CarruerType'].to_s)
          unless params['CarruerNum'].to_s == ''
            raise ECpayInvoiceRuleViolate, "[CarruerNum] must be empty when [CarruerType] is empty or 1."
          end
        elsif params['CarruerType'].to_s == '2'
          if /[A-Za-z]{2}[0-9]{14}/.match(params['CarruerNum']).nil?
            raise ECpayInvoiceRuleViolate, "[CarruerNum] must be 2 alphabets and 14 numbers when [CarruerType] is 2."
          end
        elsif params['CarruerType'].to_s == '3'
          if /^\/[A-Za-z0-9\s+-]{7}$/.match(params['CarruerNum']).nil?
            raise ECpayInvoiceRuleViolate, "[CarruerNum] must start with '/' followed by 7 alphabet and number characters when [CarruerType] is 3."
          end
        else
          raise ECpayInvoiceRuleViolate, "Unexpected value in [CarruerType]."
        end

        #[CarruerType]有值時，Print必須為0
        if params['CarruerType'].to_s != '' and params['Print'].to_s != '0'
        	raise ECpayInvoiceRuleViolate, "[Print] must be 0 when [CarruerType] has value."
        end

        # Donation = 1 => LoveCode不能為空, Print = 0
        if params['Donation'].to_s == '1'
          if params['LoveCode'].to_s.empty?
            raise ECpayInvoiceRuleViolate, "[LoveCode] cannot be empty when [Donation] is 1."
          end
          unless params['Print'].to_s == '0'
            raise ECpayInvoiceRuleViolate, "[Print] must be 0 when [Donation] is 1."
          end
        end

        #3. 比對商品名稱，數量，單位，價格，tax項目數量是否一致
        item_params = ['InvoiceItemCount', 'InvoiceItemWord', 'InvoiceItemPrice', 'InvoiceItemTaxType']
        #商品名稱含有管線 => 認為是多樣商品 *InvoiceItemName， *InvoiceItemCount ，*InvoiceItemWord， *InvoiceItemPrice InvoiceItemTaxType逐一用管線分割，計算數量後與第一個比對
        if params['InvoiceItemName'].empty?
        	raise ECpayInvoiceRuleViolate, "[InvoiceItemName] is empty."
        else
  	      if params['InvoiceItemName'].include?('|')
  	        item_cnt = params['InvoiceItemCount'].split('|').length
  	        item_params.each do |param_name|
  	          # Check if there's empty value.
  	          unless /(\|\||^\||\|$)/.match(params[param_name]).nil?
  	            raise ECpayInvoiceRuleViolate, "[#{param_name}] contains empty value."
  	          end
  	          p_cnt = params[param_name].split('|').length
  	          unless item_cnt == p_cnt
  	            raise ECpayInvoiceRuleViolate, %Q{Count of item info [#{param_name}] (#{p_cnt}) not match item count from [InvoiceItemCount] (#{item_cnt})}
  	          end
  	        end
  	        # 課稅類別[TaxType] = 9 時 => InvoiceItemTaxType 能含有1,2 3(and at least contains one 1 and other)
  	        item_tax = params['InvoiceItemTaxType'].split('|')
  	        aval_tax_type = ['1', '2', '3']
  	        vio_tax_t = (item_tax - aval_tax_type)
  	        unless vio_tax_t == []
  	          raise ECpayInvoiceRuleViolate, "Ilegal [InvoiceItemTaxType]: #{vio_tax_t}"
  	        end
  	        if params['TaxType'].to_s == '9'
  	          unless item_tax.include?('1')
  	            raise ECpayInvoiceRuleViolate, "[InvoiceItemTaxType] must contain at lease one '1'."
  	          end
  	          if item_tax.include?('2') and item_tax.include?('3')
  	            raise ECpayInvoiceRuleViolate, "[InvoiceItemTaxType] cannot contain 2 and 3 at the same time."
  	          end
  	        end
  	      else
  	        #沒有管線 => 逐一檢查後4項有無管線
  	        item_params.each do |param_name|
  	          if params[param_name].include?('|')
  	            raise "Item info [#{param_name}] contains pipeline delimiter but there's only one item in param [InvoiceItemName]"
  	          end
  	        end
  	      end
  	    end
        #4 比對所有欄位Pattern
        self.verify_param_by_pattern(params, @all_param_pattern)

      else
        raise TypeError, "Recieved argument is not a hash"
      end
    end

    #可能要寫一個hash list 轉 這五個參數的method
    # def hash_to_inv_item_params
    # end


  end

  class QueryParamVerify < PaymentVerifyBase
    include ECpayErrorDefinition
    def initialize(apiname)
      @aio_basic_param = self.get_basic_params(apiname).freeze
      @aio_conditional_param = self.get_cond_param(apiname).freeze
      @all_param_pattern = self.get_all_pattern(apiname).freeze
    end

    def verify_query_param(params)
      if params.is_a?(Hash)
        param_diff = @aio_basic_param - params.keys
        unless param_diff == []
          raise ECpayInvalidParam, "Lack required param #{param_diff}"
        end

        #Verify Value pattern of each param
        self.verify_param_by_pattern(params, @all_param_pattern)

      else
        raise TypeError, "Recieved argument is not a hash"
      end

    end

  end

  class ActParamVerify < PaymentVerifyBase
    include ECpayErrorDefinition
    def initialize(apiname)
      @aio_basic_param = self.get_basic_params(apiname).freeze
      @aio_conditional_param = self.get_cond_param(apiname).freeze
      @all_param_pattern = self.get_all_pattern(apiname).freeze
    end

    def verify_act_param(params)
      if params.is_a?(Hash)
        param_diff = @aio_basic_param - params.keys
        unless param_diff == []
          raise ECpayInvalidParam, "Lack required param #{param_diff}"
        end

        #Verify Value pattern of each param
        self.verify_param_by_pattern(params, @all_param_pattern)

      else
        raise TypeError, "Recieved argument is not a hash"
      end

    end

  end
end
