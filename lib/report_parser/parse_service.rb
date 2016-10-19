module ReportParser
  class ParseService
    def initialize(data, report_type, marketplace)
      @data = data
      @report_type = report_type
      @marketplace = marketplace
      check_report_type
    end

    def check_report_type
      p '.................'
      p @report_type
      p '.................'
      case @report_type
      when '_GET_FBA_FULFILLMENT_INVENTORY_RECEIPTS_DATA_'
        received_inventory
      when '_GET_V2_SETTLEMENT_REPORT_DATA_FLAT_FILE_V2_'
        settlement_report
      else
        Rails.logger.info('undefined report type')
      end
    end

    def received_inventory
      @data.each do |line|
        ReceivedInventory.create(received_inventory_params(line, @marketplace))
      end
      @marketplace.update_attribute(:get_received_inventory_finished, Time.now)
      ProcessDataJob.perform_later(@marketplace.user)
    end

    def settlement_report
      byebug
      # @data.each do |line|
      #   # byebug
      # end
    end

    private

    def received_inventory_params(file_line, marketplace)
      {
        marketplace: marketplace,
        received_date: file_line['received-date'].to_datetime,
        fnsku: file_line['fnsku'],
        sku: file_line['sku'],
        product_name: file_line['product-name'],
        quantity: file_line['quantity'].to_i,
        fba_shipment_id: file_line['fba-shipment-id']
      }
    end
  end
end
