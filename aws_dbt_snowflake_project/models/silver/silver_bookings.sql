{{
    config(
        materialized = 'incremental',
        unique_key = 'BOOKING_ID',
        on_schema_change = 'append_new_columns'
    )
}}

SELECT 
    BOOKING_ID,
    LISTING_ID,
    BOOKING_DATE,
    {{multiply('nights_booked','booking_amount',2)}} as TOTAL_AMOUNT,
    SERVICE_FEE,
    CLEANING_FEE,
    BOOKING_STATUS,
    CREATED_AT
FROM
    {{ref('bronze_bookings')}}
    

