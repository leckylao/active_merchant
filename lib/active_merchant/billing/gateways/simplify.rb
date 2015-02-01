module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class SimplifyGateway < Gateway
      # self.test_url = 'https://example.com/test'
      # self.live_url = 'https://example.com/live'
      require 'simplify'

      # self.supported_countries = ['US']
      # self.default_currency = 'USD'
      # self.supported_cardtypes = [:visa, :master, :american_express, :discover]

      self.homepage_url = 'https://www.simplify.com'
      self.display_name = 'Simplify Commerce'

      STANDARD_ERROR_CODE_MAPPING = {}

      def initialize(options={})
        requires!(options, :public_key, :private_key)
        Simplify::public_key = options[:public_key]
        Simplify::private_key = options[:private_key]
        super
      end

      def purchase(money, payment, options={})
        p "Money: #{money.inspect}"
        p "Credit Card: #{payment.inspect}"
        p "Credit Card year: #{payment.year.to_s[2..3]}"
        p "Gateway options: #{options.inspect}"

        post = {}
        # invoice = add_invoice(post, money, options)
        # add_payment(post, payment)
        # add_address(post, payment, options)
        # add_customer_data(post, options)

        response = Simplify::Payment.create({
          "amount" => money,
          "description" => options[:description],
          # "invoice" => invoice.id,
          "card" => {
             "expMonth" => payment.month,
             "expYear" => payment.year.to_s[2..3],
             "cvc" => payment.verification_value,
             "number" => payment.number
          }
        })

        commit('sale', response, post)
      end

      def authorize(money, payment, options={})
        post = {}
        # add_invoice(post, money, options)
        # add_payment(post, payment)
        # add_address(post, payment, options)
        # add_customer_data(post, options)

        p "Money: #{money.inspect}"
        p "Credit Card: #{payment.inspect}"
        p "Credit Card year: #{payment.year.to_s[2..3]}"
        p "Gateway options: #{options.inspect}"

        response = Simplify::Authorization.create({
          "amount" => money,
          "description" => options[:description],
          "card" => {
             "expMonth" => payment.month,
             "expYear" => payment.year.to_s[2..3],
             "cvc" => payment.verification_value,
             "number" => payment.number
          }#,
          # "reference" => "KP-76TBONES",
          # "currency" => options[:currency]
        })

        commit('authonly', response, post)
      end

      def capture(money, authorization, options={})
        commit('capture', response, post)
      end

      def refund(money, authorization, options={})
        Simplify::Refund.create({
          "amount" => money,
          # "payment" => "[PAYMENT ID]",
          # "reason" => "Refund Description",
          # "reference" => "76398734634"
        })

        commit('refund', response, post)
      end

      def void(authorization, options={})
        commit('void', response, post)
      end

      def verify(credit_card, options={})
        MultiResponse.run(:use_first_response) do |r|
          r.process { authorize(100, credit_card, options) }
          r.process(:ignore_result) { void(r.authorization, options) }
        end
      end

      def supports_scrubbing?
        true
      end

      def scrub(transcript)
        transcript
      end

      private

      def add_customer_data(post, options)
        Simplify::Customer.create({
          # "email" => "customer@mastercard.com",
          # "name" => "Customer Customer",
          "card" => {
             "expMonth" => "11",
             "expYear" => "19",
             "cvc" => "123",
             "number" => "5555555555554444"
          },
          "reference" => "Ref1"
        })
      end

      def add_address(post, creditcard, options)
      end

      def add_tax(id, rate, label)
        Simplify::Tax.create({
          "rate" => rate,
          "label" => label
        })
      end

      def add_invoice(post, money, options)
        post[:amount] = amount(money)
        post[:currency] = (options[:currency] || currency(money))

        Simplify::Invoice.create({
          # "memo" => "This is a memo",
          "items" => [
             {
                "amount" => post[:amount],
                # "tax" => add_tax(0, 'null').id,
                "quantity" => "1"
             }
          ],
          # "email" => "customer@mastercard.com",
          # "name" => "Customer Customer",
          "note" => options[:description],
          "reference" => options[:order_id]
        })
      end

      def add_payment(post, payment)
      end

      def parse(body)
        {}
      end

      def commit(action, response, parameters)
        # url = (test? ? test_url : live_url)
        # response = parse(ssl_post(url, post_data(action, parameters)))

        Response.new(
          success_from(response),
          message_from(response),
          response,
          authorization: authorization_from(response),
          test: test?
        )
      end

      def success_from(response)
        response['paymentStatus'] == 'APPROVED'
      end

      def message_from(response)
        response['paymentStatus']
      end

      def authorization_from(response)
      end

      def post_data(action, parameters = {})
      end
    end
  end
end
