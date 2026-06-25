{% set congigs =[
    {
    "table" : "AIRBNB.SILVER.SILVER_BOOKINGS",
    "columns": "SILVER_BOOKINGS. * ",
    "alias": "SILVER_bookings"
    },
    {
    "table" : "AIRBNB.SILVER.SILVER_LISTINGS",
    "columns": "SILVER_listings.host_id,SILVER_listings.PROPERTY_TYPE,SILVER_listings.ROOM_TYPE,SILVER_listings.CITY,SILVER_listings.COUNTRY,SILVER_listings.ACCOMMODATES,SILVER_listings.BEDROOMS,SILVER_listings.BATHROOMS,SILVER_listings.PRICE_PER_NIGHT,SILVER_listings.price_per_night_tag,SILVER_listings.CREATED_AT as created_at_lsiting",
    "alias": "SILVER_listings",
    "join_condition": "SILVER_bookings.listing_id = SILVER_listings.listing_id"
    },
    {
    "table" : "AIRBNB.SILVER.SILVER_HOSTS",
    "columns": "SILVER_hosts.HOST_NAME,SILVER_hosts.HOST_SINCE,SILVER_hosts.IS_SUPERHOST,SILVER_hosts.RESPONSE_RATE,SILVER_hosts.PRESPONSE_RATE_QUALITY,SILVER_hosts.CREATED_AT as created_at_host",
    "alias": "SILVER_hosts",
    "join_condition": "SILVER_listings.host_id = SILVER_hosts.host_id"
    }


]%}


SELECT
    {% for config in congigs %}
    {{config['columns']}}{% if not loop.last %},{% endif %}
    {% endfor %} 
FROM
    {% for config in congigs%}
    {% if loop.first %}
        {{config['table']}} as {{config['alias']}}
    {% else %}
        LEFT JOIN {{config['table']}} as {{config['alias']}}
        ON {{config['join_condition']}}
        {% endif %}
    {% endfor %}