{% macro load_all_walmart() %}

    {% if execute %}
        {% do copy_into_department() %}
        {% do copy_into_fact() %}
        {% do copy_into_stores() %}

    {% endif %}
{% endmacro%}