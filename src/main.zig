const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
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

    pub fn Fill(self: *Self, quantity: Quantity) !void {
        if (quantity > self.remaining_quantity) {
            return LogicError.QuantityExceeded;
        }

        self.remaining_quantity -= quantity;
    }
};

// Type for holding the list of orders.
const OrderList = std.ArrayList(*Order);

const OrderModify = struct {
    order_id: OrderId,
    side: Side,
    price: Price,
    quantity: Quantity,

    const Self = @This();

    pub fn ToOrderPointer(self: Self, allocator: std.mem.Allocator, order_type: OrderType) !*Order {
        const order = try allocator.create(Order);
        errdefer allocator.destroy(order);
        order.* = .{ .initial_quantity = self.quantity, .side = self.side, .price = self.price, .order_type = order_type, .order_id = self.order_id, .remaining_quantity = self.quantity };
        return order;
    }
};

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

test "gives correct order pointer" {
    var order_modify = OrderModify{ .order_id = 1, .price = 1, .quantity = 1, .side = Side.Buy };
    const alloc = std.testing.allocator;
    const order = order_modify.ToOrderPointer(alloc, OrderType.FillAndKill);
    defer alloc.free(order);
    try std.testing.expect(order.initial_quantity == 1);
}
