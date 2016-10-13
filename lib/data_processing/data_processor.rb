module DataProcessing
  class DataProcessor
    class << self
      def prices_processing(received_inventories)
        received_inventories.each do |item|
          inventory = Inventory.where('msku = ? AND (date_purchased <= ? OR date_purchased IS NULL)', item.sku, item.received_date).first

          next unless inventory.present?

          if item.quantity.positive?
            item.update_attributes(price_per_unit: inventory.price, price_total: inventory.price * item.quantity)
          else
            item.update_attribute(:price_per_unit, inventory.price)
          end
        end
      end

      def fulfillment_inbound_filling(received_inventories_priced, current_user)
        shipments_without_price = ReceivedInventory.where(price_total: nil).distinct.pluck(:fba_shipment_id)
        shipment_ids_all_items_priced = received_inventories_priced.where.not(fba_shipment_id: shipments_without_price).distinct.pluck(:fba_shipment_id)
        shipment_ids_all_items_priced.each do |item|
          request = ActiveRecord::Base.connection.execute("SELECT SUM(quantity) AS total_quantity, SUM(price_total) AS total_price FROM received_inventories WHERE fba_shipment_id = '#{item}'")
          shipment_items_quantity = request.field_values('total_quantity').first
          shipment_total_cost = request.field_values('total_price').first
          FulfillmentInboundShipment.create(fulfillment_inbound_shipment_params(shipment_total_cost, shipment_items_quantity, item, current_user))
        end
      end

      private

      def fulfillment_inbound_shipment_params(cost, units, shipment_id, current_user)
        marketplace_id = ReceivedInventory.where(fba_shipment_id: shipment_id, marketplace: current_user.marketplaces).distinct.pluck(:marketplace_id).first
        marketplace = Marketplace.find(marketplace_id)

        {
          marketplace: marketplace,
          shipment_id: shipment_id,
          price: cost,
          total_received_units: units
        }
      end
    end
  end
end