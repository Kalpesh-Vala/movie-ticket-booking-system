// MongoDB initialization script

// Create movie_booking database
db = db.getSiblingDB('movie_booking');

// Create collections with schema validation

// Users collection
db.createCollection("users", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["email", "password", "first_name", "last_name", "created_at"],
      properties: {
        email: {
          bsonType: "string",
          pattern: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        },
        password: {
          bsonType: "string",
          minLength: 8
        },
        first_name: {
          bsonType: "string",
          minLength: 1
        },
        last_name: {
          bsonType: "string",
          minLength: 1
        },
        phone_number: {
          bsonType: "string"
        },
        date_of_birth: {
          bsonType: "date"
        },
        is_active: {
          bsonType: "bool"
        },
        created_at: {
          bsonType: "date"
        },
        updated_at: {
          bsonType: "date"
        }
      }
    }
  }
});

// Bookings collection
db.createCollection("bookings", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["user_id", "showtime_id", "seats", "total_amount", "status", "created_at"],
      properties: {
        user_id: {
          bsonType: "string"
        },
        showtime_id: {
          bsonType: "string"
        },
        seats: {
          bsonType: "array",
          items: {
            bsonType: "string"
          }
        },
        total_amount: {
          bsonType: "double",
          minimum: 0
        },
        status: {
          enum: ["pending_payment", "confirmed", "cancelled", "refund_pending", "refunded"]
        },
        lock_id: {
          bsonType: "string"
        },
        lock_expires_at: {
          bsonType: "date"
        },
        payment_transaction_id: {
          bsonType: "string"
        },
        confirmed_at: {
          bsonType: "date"
        },
        cancelled_at: {
          bsonType: "date"
        },
        cancellation_reason: {
          bsonType: "string"
        },
        created_at: {
          bsonType: "date"
        },
        updated_at: {
          bsonType: "date"
        }
      }
    }
  }
});

// Transaction logs collection
db.createCollection("transaction_logs", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["transaction_id", "booking_id", "amount", "payment_method", "status", "created_at"],
      properties: {
        transaction_id: {
          bsonType: "string"
        },
        booking_id: {
          bsonType: "string"
        },
        amount: {
          bsonType: "double"
        },
        payment_method: {
          enum: ["credit_card", "debit_card", "digital_wallet", "net_banking"]
        },
        status: {
          enum: ["pending", "success", "failed", "refunded"]
        },
        payment_details: {
          bsonType: "object"
        },
        gateway_response: {
          bsonType: "object"
        },
        failure_reason: {
          bsonType: "string"
        },
        created_at: {
          bsonType: "date"
        },
        updated_at: {
          bsonType: "date"
        }
      }
    }
  }
});

// Notification logs collection
db.createCollection("notification_logs", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["event_id", "notification_type", "recipient", "status", "created_at"],
      properties: {
        event_id: {
          bsonType: "string"
        },
        notification_type: {
          enum: ["email", "sms", "push"]
        },
        recipient: {
          bsonType: "string"
        },
        subject: {
          bsonType: "string"
        },
        status: {
          enum: ["sent", "failed", "pending"]
        },
        event_data: {
          bsonType: "object"
        },
        created_at: {
          bsonType: "date"
        },
        sent_at: {
          bsonType: "date"
        }
      }
    }
  }
});

// Create indexes for performance
db.users.createIndex({ "email": 1 }, { unique: true });
db.users.createIndex({ "created_at": 1 });

db.bookings.createIndex({ "user_id": 1 });
db.bookings.createIndex({ "showtime_id": 1 });
db.bookings.createIndex({ "status": 1 });
db.bookings.createIndex({ "created_at": -1 });
db.bookings.createIndex({ "lock_expires_at": 1 });

db.transaction_logs.createIndex({ "transaction_id": 1 }, { unique: true });
db.transaction_logs.createIndex({ "booking_id": 1 });
db.transaction_logs.createIndex({ "status": 1 });
db.transaction_logs.createIndex({ "created_at": -1 });

db.notification_logs.createIndex({ "event_id": 1 });
db.notification_logs.createIndex({ "recipient": 1 });
db.notification_logs.createIndex({ "notification_type": 1 });
db.notification_logs.createIndex({ "created_at": -1 });

// Insert sample data
const sampleUsers = [
  {
    _id: "user123",
    email: "john.doe@example.com",
    password: "$2b$10$rOqL.ZBcRlpHqQ9C7i3QPuF4dQ1dGzHpZKvQaI7g1K.2j3l4m5n6o", // "password123"
    first_name: "John",
    last_name: "Doe",
    phone_number: "+1234567890",
    is_active: true,
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    _id: "user456",
    email: "jane.smith@example.com",
    password: "$2b$10$rOqL.ZBcRlpHqQ9C7i3QPuF4dQ1dGzHpZKvQaI7g1K.2j3l4m5n6o", // "password123"
    first_name: "Jane",
    last_name: "Smith",
    phone_number: "+1234567891",
    is_active: true,
    created_at: new Date(),
    updated_at: new Date()
  }
];

try {
  db.users.insertMany(sampleUsers);
  print("Sample users inserted successfully");
} catch (e) {
  print("Users already exist or error inserting: " + e);
}

print("MongoDB initialization completed successfully!");