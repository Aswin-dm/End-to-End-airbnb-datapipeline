{% macro multiply(a,b,percision) %}
    round({{a}} * {{b}},{{percision}} )
{% endmacro %}