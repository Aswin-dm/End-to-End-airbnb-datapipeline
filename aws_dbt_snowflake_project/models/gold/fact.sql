{% set congigs =[
    {          
    "table" : "AIRBNB.GOLD.OBT",
    "columns": "GOLD_OBT.BOOKING_ID,GOLD_OBT.LISTING_ID,GOLD_OBT.HOST_ID,GOLD_OBT.TOTAL_AMOUNT,GOLD_OBT.SERVICE_FEE,GOLD_OBT.CLEANING_FEE,GOLD_OBT.ACCOMMODATES,GOLD_OBT.BEDROOMS,GOLD_OBT.BATHROOMS,GOLD_OBT.PRICE_PER_NIGHT,GOLD_OBT.RESPONSE_RATE ",
    "alias": "GOLD_OBT"
    },
    {
    "table" : "AIRBNB.GOLD.DIM_LISTINGS",
    "columns": "",
    "alias": "DIM_listings",
    "join_condition": "GOLD_OBT.LISTING_ID = DIM_listings.LISTING_ID"
    },
    {
    "table" : "AIRBNB.GOLD.DIM_HOSTS",
    "columns": "",
    "alias": "DIM_hosts",
    "join_condition": "GOLD_OBT.HOST_ID = DIM_HOSTS.HOST_ID"
    }


]%}


SELECT

    {{congigs[0]['columns']}}
   
FROM
    {% for config in congigs%}
    {% if loop.first %}
        {{config['table']}} as {{config['alias']}}
    {% else %}
        LEFT JOIN {{config['table']}} as {{config['alias']}}
        ON {{config['join_condition']}}
        {% endif %}
    {% endfor %}