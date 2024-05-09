const std = @import("std");
const ArrayList = std.ArrayList;

const OrderType = enum { GoodTillCancel, FillAndKill };
const Side = enum { Buy, Sell };
const Price = i32;
const OrderId = u32;
const Quantity = u32;
const LevelInfo = struct { price: i32, quantity: u32 };

const OrderbookLevelInfos = struct {
    bids: ArrayList(LevelInfo),
    asks: ArrayList(LevelInfo),

    const Self = @This();

    pub fn GetBids(self: Self) ArrayList(LevelInfo) {
        return self.bids;
    }

    pub fn GetAsks(self: Self) ArrayList(LevelInfo) {
        return self.asks;
    }
};

const LogicError = error{QuantityExceeded};

const Order = struct {
    order_type: OrderType,
    order_id: OrderId,
    side: Side,
    price: Price,
    initial_quantity: Quantity,
    remaining_quantity: Quantity,

    const Self = @This();

    pub fn GetOrderId(self: Self) OrderId {
        return self.order_id;
    }

    pub fn GetOrderType(self: Self) OrderType {
        return self.order_type;
    }

    pub fn GetSide(self: Self) Side {
        return self.side;
    }

    pub fn GetPrice(self: Self) Price {
        return self.price;
    }

    pub fn GetInitialQuantity(self: Self) Quantity {
        return self.initial_quantity;
    }

    pub fn GetRemainingQuantity(self: Self) Quantity {
        return self.remaining_quantity;
    }

    pub fn Fill(self: *Self, quantity: Quantity) !void {
        if (quantity > self.remaining_quantity) {
            return LogicError.QuantityExceeded;
        }

        self.remaining_quantity -= quantity;
    }
};

// Type for holding the list of orders.
const OrderList = std.ArrayList(*Order);

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
}

test "fill returns logic error if exceeds quantity" {
    var order = Order{ .order_id = 1, .order_type = OrderType.GoodTillCancel, .side = Side.Buy, .price = 1, .initial_quantity = 1, .remaining_quantity = 1 };
    try std.testing.expect(order.Fill(20) == LogicError.QuantityExceeded);
    try std.testing.expect(order.Fill(1) != LogicError.QuantityExceeded);
    try std.testing.expect(order.remaining_quantity == 0);
}
