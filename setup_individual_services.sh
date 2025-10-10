#!/bin/bash

# Individual Services Setup Script
# Provides a menu to start services one by one

echo "🎬 Movie Ticket Booking System - Individual Setup"
echo "================================================="

# Function to print status
print_status() {
    echo "[INFO] $1"
}

print_success() {
    echo "[SUCCESS] $1"
}

print_error() {
    echo "[ERROR] $1"
}

print_menu() {
    echo ""
    echo "📋 Setup Menu:"
    echo "  1. Setup Infrastructure (PostgreSQL, MongoDB, Redis, RabbitMQ)"
    echo "  2. Setup Kong Gateway"
    echo "  3. Setup User Service"
    echo "  4. Setup Cinema Service"
    echo "  5. Setup Payment Service"
    echo "  6. Setup Booking Service"
    echo "  7. Setup Notification Service"
    echo "  8. Check Services Status"
    echo "  9. Stop All Services"
    echo "  0. Exit"
    echo ""
    echo "  A. Auto Setup All (Infrastructure → Kong → All Services)"
    echo "  T. Run Integration Tests"
    echo ""
}

# Function to wait for user input
wait_for_input() {
    echo ""
    read -p "Press Enter to continue or Ctrl+C to exit..."
}

# Auto setup function
auto_setup() {
    echo ""
    print_status "Starting automatic setup of all services..."
    
    echo ""
    echo "Step 1/7: Setting up Infrastructure..."
    ./setup_infrastructure.sh
    if [ $? -ne 0 ]; then
        print_error "Infrastructure setup failed"
        return 1
    fi
    
    echo ""
    echo "Step 2/7: Setting up Kong Gateway..."
    ./setup_kong.sh
    if [ $? -ne 0 ]; then
        print_error "Kong Gateway setup failed"
        return 1
    fi
    
    echo ""
    echo "Step 3/7: Setting up User Service..."
    ./setup_user_service.sh
    if [ $? -ne 0 ]; then
        print_error "User Service setup failed"
        return 1
    fi
    
    echo ""
    echo "Step 4/7: Setting up Cinema Service..."
    ./setup_cinema_service.sh
    if [ $? -ne 0 ]; then
        print_error "Cinema Service setup failed"
        return 1
    fi
    
    echo ""
    echo "Step 5/7: Setting up Payment Service..."
    ./setup_payment_service.sh
    if [ $? -ne 0 ]; then
        print_error "Payment Service setup failed"
        return 1
    fi
    
    echo ""
    echo "Step 6/7: Setting up Booking Service..."
    ./setup_booking_service.sh
    if [ $? -ne 0 ]; then
        print_error "Booking Service setup failed"
        return 1
    fi
    
    echo ""
    echo "Step 7/7: Setting up Notification Service..."
    ./setup_notification_service.sh
    if [ $? -ne 0 ]; then
        print_error "Notification Service setup failed"
        return 1
    fi
    
    echo ""
    print_success "🎉 All services have been set up successfully!"
    echo ""
    echo "🌐 System Access Points:"
    echo "  - Kong Gateway:      http://localhost:8000"
    echo "  - Kong Admin:        http://localhost:8001"
    echo "  - User Service:      http://localhost:8080"
    echo "  - Cinema Service:    http://localhost:8081"
    echo "  - Booking Service:   http://localhost:8082"
    echo "  - Payment Service:   http://localhost:8083"
    echo "  - Notification Service: http://localhost:8084"
    echo ""
    echo "📊 Management Interfaces:"
    echo "  - RabbitMQ Management: http://localhost:15672 (admin/admin123)"
    echo "  - MongoDB Express:   http://localhost:8081 (admin/admin123)"
    echo "  - pgAdmin:           http://localhost:8080 (admin@movietickets.com/admin123)"
    echo "  - Redis Commander:   http://localhost:8082"
}

# Main menu loop
while true; do
    print_menu
    read -p "Enter your choice (0-9, A, T): " choice
    
    case $choice in
        1)
            echo ""
            print_status "Setting up Infrastructure Services..."
            ./setup_infrastructure.sh
            wait_for_input
            ;;
        2)
            echo ""
            print_status "Setting up Kong Gateway..."
            ./setup_kong.sh
            wait_for_input
            ;;
        3)
            echo ""
            print_status "Setting up User Service..."
            ./setup_user_service.sh
            wait_for_input
            ;;
        4)
            echo ""
            print_status "Setting up Cinema Service..."
            ./setup_cinema_service.sh
            wait_for_input
            ;;
        5)
            echo ""
            print_status "Setting up Payment Service..."
            ./setup_payment_service.sh
            wait_for_input
            ;;
        6)
            echo ""
            print_status "Setting up Booking Service..."
            ./setup_booking_service.sh
            wait_for_input
            ;;
        7)
            echo ""
            print_status "Setting up Notification Service..."
            ./setup_notification_service.sh
            wait_for_input
            ;;
        8)
            echo ""
            ./check_services_status.sh
            wait_for_input
            ;;
        9)
            echo ""
            print_status "Stopping all services..."
            ./stop_all_services.sh
            wait_for_input
            ;;
        [aA])
            auto_setup
            wait_for_input
            ;;
        [tT])
            echo ""
            print_status "Running integration tests..."
            if [ -f "./test_integration.sh" ]; then
                ./test_integration.sh
            else
                print_error "Integration test script not found"
            fi
            wait_for_input
            ;;
        0)
            echo ""
            print_success "Goodbye! 👋"
            exit 0
            ;;
        *)
            echo ""
            print_error "Invalid choice. Please enter a number between 0-9, A, or T."
            sleep 2
            ;;
    esac
done