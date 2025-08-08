workspace "PP Taxi Booking" "System to include TAXI booking in PP app" {
    !identifiers hierarchical
    !impliedRelationships true

    model {
        u = person "User" {
            description "Priority Pass Customer"
        }

        adops = person "PP Ad Ops" {
            description "Priority Pass Ad and Partner Manager"
            tags "PP"
        }

        pp = softwareSystem "Priority Pass TAXI booking" {
            app = container "PP Mobile App" {
                login_view = component "Login"
                flight_view = component "Flight Details"
                find_rides_view = component "Find Rides"
                book_ride_view = component "Book Ride"
                ride_status_view = component "Ride Status"
                tags "App" "PP"
            }
            flights = container "Flights Info Service"  {
                tags "PP"
                description "Looks-up the flight details and closest airports"
                technology "AWS Lambda, Node.js"
            }
            taxi_service = container "TAXI middleware microservices" {
                tags "PP"
                description "Provides middleware services for App interacting with TAXI vendor(s)"
                technology "AWS Lambda, Node.js"
                    estimator = component "Route Estimator"
                    booking = component "Ride Booking Handler"
                    status = component "Ride Status Handler"
            }
            db = container "Customer Database" {
                tags "Database" "PP"
                technology "Existing PP Customer DB"
                auth = component "Authentication"
                user_data = component "User Data"
                tags "PP"
                description "Provides Auth services and Serves Customer Data"
            }
            notifications = container "Notifications Manager" {
                tags "PP", "Service"
                technology "Node.JS"
                description "Handles storing of notification subscriptions and delivery of timely notifications"
                manager = component "Subscription Manager"
                pusher = component "Periodic Notification Dispatcher"
                db = component "Subscriptions database"
            }
            taxi_partners = container "TAXI Partners Database" {
                tags "Database" "PP"
                technology "AWS RDS"
                vendors = component "Vendor Details"
                ads = component "Vendor Promotions"
                pp_promo = component "PP Ads"
                tags "PP"
                description "Stores details of all available TAXI partners"
            }
            ads = container "Partner Promo Service" {
                description "Serves the Adveritsing and Promotion content to PP app and Partner App"
                external_content = component "External Content" {
                    technology "AWS Lambda, Node.js"
                    description "Serves appropriate Partner content to the PP App"
                }
                pp_content = component "Priority Pass Content" {
                    technology "AWS Lambda, Node.js"
                    description "Serves appropriate PP content to the TAXI vendor"

                }
                analytics = component "Promotion Analytics and Reporting"
                admin = component "Promotion Management CRUD"
                db = component "Promotions Database" {
                    tags "Database" "PP"
                    technology "AWS RDS"
                    tags "PP"
                    description "Stores Promotions and Stats"
                }
            }
            logging = container "Logging Service" {
                description "Logs usage, errors and transactions"
            }
            tags "PP"
        }


        group "TAXI vendor(s)" {
            taxi_app = softwareSystem "TAXI App" {
                tags "App" "TAXI"
                description "TAXI vendors own app"
            }
            taxi_api = softwareSystem "TAXI Backend API" {
                tags "TAXI"
                description "TAXI vendors API service for searching and booking"
            }
            taxi_car = element "TAXI Car"
        }

/*
        taxi = softwareSystem "TAXI" {
            app = container "TAXI App" {
                tags "App" "TAXI"
                description "TAXI vendors own app"
            }
            api = container "TAXI Backend API" {
                tags "TAXI"
                description "TAXI vendors API service for searching and booking"
            }
            car = container "TAXI Car"
        }
*/

        u -> pp "Uses Priority Pass to book TAXI"
        u -> pp.app "Uses"

        adops -> pp.ads "Manages"
        adops -> pp.ads.analytics "Reviews performance"
        adops -> pp.ads.admin "Manages Promotions"

        pp -> taxi_api "Finds and book ride"
        pp -> taxi_app "Launches"
        taxi_api -> pp.ads "Fetches PP ads"

        pp.app -> pp.db "Authenticates user and get details" HTTPS

        pp.app.login_view -> pp.db.auth "Authenticates User" HTTPS
        pp.app.login_view -> pp.db.user_data "Queries User Data and Loyalty Status" HTTPS
        pp.app.flight_view -> pp.flights "Queries flight details" HTTPS
        pp.app.flight_view -> pp.ads "Fetches Partner Promo Content" HTTPS
        pp.app.find_rides_view -> pp.taxi_service.estimator "Queries available rides" HTTPS
        pp.app.find_rides_view -> pp.ads.external_content "Fetches Partner Promo Content" HTTPS
        pp.app.book_ride_view -> pp.taxi_service.booking "Books ride" HTTPS
        pp.app.ride_status_view -> pp.taxi_service.status "Polls for updates" HTTPS
        pp.app.book_ride_view -> pp.notifications.manager "Subsribes for notification" HTTPS
        pp.app -> taxi_app "Launches" "Deep-link URL"

        pp.taxi_service -> pp.taxi_partners "Fetches regional operators and details" SQL
        pp.taxi_service.estimator -> taxi_api "Retrieves available rides" HTTPS
        pp.taxi_service.booking -> taxi_api "Makes a booking" HTTPS
        pp.taxi_service.status -> pp.app.ride_status_view "Updates ride status" WebSocket/Push
        pp.taxi_service -> pp.logging "Logs Error, Transactions, Usage" EventBridge

        pp.notifications.manager -> pp.notifications.db "Uses"
        pp.notifications.pusher -> pp.notifications.db "Uses"
        pp.notifications.pusher -> pp.app "Sends Travel Soon Reminder" Push
        pp.notifications.pusher -> pp.logging "Logs Errors and Usage" EventBridge

        taxi_api -> pp.taxi_service.status "Updates ride status" WebHook
        taxi_api -> taxi_app "Ride and Content Sync"
        taxi_api -> taxi_car "Dispatches"

        taxi_api -> pp.ads.pp_content "Fetches PP promo content" HTTPS
        pp.ads.external_content -> pp.ads.db "Fetches Partner Content" SQL
        pp.ads.pp_content -> pp.ads.db "Fetches PP Content" SQL
        pp.ads -> pp.logging "Logs Error, Usage" EventBridge
        pp.ads.pp_content -> pp.ads.analytics "Logs traffic"
        pp.ads.external_content -> pp.ads.analytics "Logs traffic"
        pp.ads.admin -> pp.ads.db "Updates"
        pp.ads.analytics -> pp.ads.db "Uses"
    }

    views {

        dynamic pp {
            title "Ordering a TAXI"
            u -> pp.app "Open and Login to the PP App"
            u -> pp.app "Enters flight number or airport details (prefilled by location) and time"
            pp.app -> pp.flights "Looks up the flight and airport details"
            pp.app -> pp.taxi_service "Queries available rides and times" HTTPS
            pp.taxi_service -> taxi_api "Retrieves available rides" HTTPS
            pp.app -> pp.ads "Fetches Partner Promo Content" HTTPS
            u -> pp.app "Selects the desired ride"
            pp.app -> pp.taxi_service "Books ride" HTTPS
            pp.taxi_service -> taxi_api "Makes a booking" HTTPS
            pp.app -> pp.taxi_service "Polls for updates" HTTPS
            taxi_api -> pp.taxi_service "Updates ride status" WebHook
            pp.taxi_service -> pp.app "Send push updates on status"
            autolayout tb
        }


        systemContext pp {
            include *
            autolayout tb
        }

        container pp {
            include *
            autolayout tb
        }

        component pp.app {
            include *
            autolayout tb
        }

        component pp.taxi_service {
            include *
            autolayout tb
        }

        component pp.ads {
            include *
            autolayout tb
        }

        component pp.db {
            include *
            autolayout tb
        }

        component pp.notifications {
            include *
            autolayout tb
        }

        styles {
            element "Element" {
                shape roundedbox
            }
            element "Person" {
                shape person
                background lightblue
            }
            element "Database" {
                shape cylinder
            }
            element "Boundary" {
                strokeWidth 5
            }
            relationship "Relationship" {
                thickness 4
                routing curved
            }
            element "App" {
                shape MobileDevicePortrait
            }
            element "PP" {
            }
            element "TAXI" {
                background lightgreen
            }
        }
        branding {
            logo https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/Priority_Pass_logo.svg/330px-Priority_Pass_logo.svg.png
        }
    }

}
