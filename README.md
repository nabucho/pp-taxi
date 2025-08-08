# Priority Pass in-app TAXI ordering

Priority Pass customers use the Priority Pass app to navigate their way at the airports to visit Priority Pass Lounges.
Goal of this project is to provide additional value to the customers by make it easier to use the App to book their transport to airport, especially in countries they do not know well and need trustworthy solution - one provided by reliable partner in the App they already own.

## Use Cases and Value Proposition

1. Customer wants to get to the Airport in time for planned departure and books transport, (v2) ideally without 3rd party app
2. Customer wants to get reminded to book transport in time on the phone
3. (v2) Customer wants to get from airport quickly - prebooks pick-up

**Benefits:**
### Priority Pass Customer
- prefilled required drop-off location and times
- estimated trip duration
- timely notification for ride booking
- best offers based on customer preferences
- (v2) access the relevant TAXI vendor in countries where global brands do not operate, without need to download and register for another unknown service

### TAXI partner
- exposure of ride service for travellers not aware of the service
- ability to promote appropriate level of service - Limo, XL, Cheap - based on Priority Pass tier customer is likely to prefer

### Collinson
- increased utility of Priority Pass app and thus increased usage
- ability to provide additional benefit to Customers - discount on transport, free transport promotion
- additional incremental revenue stream from ride bookings
- promote in airport services provided by Priority Pass on arrival inside TAXI vendor's app

## Visual mock-up
Solution introduces following views in the Priority Pass application:
1. [Flight search and lookup by flight code](https://share.balsamiq.com/c/tPvkUGmFmwG3WkgC1XyjBm.jpg)
2. [Flight details](https://share.balsamiq.com/c/7Usfmb2oymbjZ4Q1o4LTup.jpg)
3. [Airport travel details entry, time and cost estimates](https://share.balsamiq.com/c/caioLS36r7fFQggRk1pPgr.jpg)
4. [Ride variant selection and booking](https://share.balsamiq.com/c/eDch2NX61yXB2Ax8ynANwi.jpg)
5. (v2) Ride tracking
6. (v2) Payment in PP App, or from stored card-on-file in Priority Pass

[Full use-case Mockup](https://balsamiq.cloud/sa14bnr/pabg16u)

## Architecture Overview and System Design
### C4 diagram

### Architectura decisions

**Microservice model with Backend processing of partner interactions**
Separating communication with partners to the backend allows flexibility, keeping FE app just a View
- changing APIs of partner without need for app update
- changing of partner
- support for multiple partners
- flexible ordering and filtering logic

**RESTful API over HTTPS**
- standard and easy to understand and extend
- secure and compatible even under public networks, VPNs and hotel limited wifis
- separates underlying modes and implementation - eg Customer Database, Auth, Logging - for better separation

**Serverless AWS Lambda functions for backend components**
- quick and scalable deployment for stateless  logic - search, book, log...
- easy to secure and make HA using AWS API Gateway, along with validation of payloads and logging

**Using vendor's app for booking**
- as a MVP, instead of implementing full ride interface and payments, deep-link to vendor's own app opening a prefilled booking screen is executed

### Data Models (simplified)

**Notification Subscriptions**
| Field name      | Description |
|--|--|
| pp_user_id      | Priority Pass customer ID |
| from_name       | Transport pickup point name |
| from_lat        | Transport pickup point latitude |
| from_lon        | Transport pickup point longtitude |
| to_name         | Transport dropoff point name |
| to_lat          | Transport dropoff point lat |
| to_lon          | Transport dropoff point longtitude |
| flight_code     | Flight Code |
| flight_departure| Flight Departure |
| notif_time      | Time to send notification |
| travel_time     | Estimated travel time |
| status          | Active, Disabled, Sent, Delivered, Failed |

**TAXI vendors directory**
| Field name      | Description |
|--|--|
| id              | slug
| name            | string
| service_area    | n-n mapping table (IATA codes)


**Airport Drop-off points**
| Field name      | Description |
|--|--|
| airport_code    | Airport code
| dropoff_name    | Terminal 1, Terminal 2, ...
| dropoff_lat     | latitude
| dropoff_lon     | lontitude

**Partner promo content**
| Field name      | Description |
|--|--|
| partner_id      | fk from TAXI vendors
| placement_id    | home, search, booking combination
| url             | destination, if clickable
| img             | card visual
| targeting       | ruleset for targeting based on location, search and user attributes
| from            | date time
| to              | date time
| cpm             | value for PP
| priority        | relative priority

**Priority Pass promo content**
| Field name      | Description |
|--|--|
| partner_ids     | list of ids from targeted TAXI vendors
| placement_id    | home, search, booking combination
| url             | destination, if clickable
| img             | card visual
| targeting       | ruleset for targeting based on location, search and user attributes
| from            | date time
| to              | date time
| cpm             | value for PP
| priority        | relative priority


## Future Improvements
- Work with multiple TAXI vendors, so every country and city is covered even in case global vendors are not present
- Implement complete ride tracking inside Priority Pass, to eliminate need for 3rd party App
- Implement on arrival pickup booking flows
- Optimise selection of offered rides from multiple TAXI vendors contracted in the same region based on time, cost and service level

## Omissions
- Existing components of App (login, CRM database services, Flight Lookup) are not described in detail
- Payment processing flows is not described in detail, as it should be considered reusable component of Priority Pass App
- Logging - usage, transactions and errors are omitted as likely already existing in PP app
- Currently final booking, payment and tracking is handled directly in 3rd party app
- Detailed data schema types and API specifications to be added
- decisions on technology - best to fit existing frameworks and patterns for maintainability, existing DB solution, etc.
- Error handling - retries, error screens

## Required additional discovery
- APIs available for TAXI vendor - route planner and estimator, booking, status checking, notification subscription
- If vendor operates in-app advertising solution where PP can manage the ads to be displayed in partner's app
- partner's business model for ride booking via PP app ( revenue share, flat fee, ...) and payments via PP app
- ride bookings reporting available for consolidation
- area coverage of global vendors to assess need to incorporate multi-vendor solution

# Internal To Do
- [ ] redo the C4 model in LikeC4 syntax for better readability and visualisation
- [ ] extend the model for omitted components
