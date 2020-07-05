import pandas as pd
import numpy as np
from collections import Counter
import requests

class MyAviasalesParser:
    """ 
    This is a class for parsing information about tickets for the last 48 hours from aviasales.com.
    API request returns departure and destination places, dates, number of changes, cost of the ticket,
    distance between departure and destination, time and date of the moment when the ticket was found,
    site of purchase
    Connection to the REST API is established with the use of token.
    """
    
    def __init__(self, url):
        try:
            self.__req = requests.get(url, timeout = 10).json()
        
        except requests.exceptions.ReadTimeout:
            print('Read timeout occured')
        except requests.exceptions.ConnectTimeout:
            print('Connection timeout occured')
        except requests.exceptions.ConnectionError:
            print('Connection Error occured')
        except requests.exceptions.HTTPError as err:
            print('HTTP Error occured')
    
    def get_data(self):
        """
        Gets needed data from the rest request
        """
        if self.__req is not None or self.__req.status_code:
            data = self.__req['data']
            return data
        else:
            print('No data recieved')
    
    @staticmethod
    def number_of_chages_value(data):
        """
        Collect the information about the number of changes and cost of the ticket
        into the dictionary 
        """
        
        dictionary = {}
        for elem in data:
            if elem['number_of_changes'] not in dictionary.keys():
                dictionary[elem['number_of_changes']] = [elem['value']]
            else:
                dictionary[elem['number_of_changes']].append(elem['value'])
        return dictionary
    
    @staticmethod
    def gates_aggregation(data, most_comm = 15):
        """
        Count number of gates in founded tickets
        """
        all_gates = [data[i]['gate'] for i in range(len(data))]
        count_number_of_gates = Counter(all_gates).most_common(most_comm)
        
        return count_number_of_gates
    
    @staticmethod
    def dates_costs_aggregation(data, most_comm = 10):
        """
        Calculate mean price for different dates
        """
        all_dates_costs = [(data[i]['depart_date'], data[i]['value']) for i in range(len(data))]
        all_dates_costs_df = pd.DataFrame(all_dates_costs, columns = ['date', 'value']).sort_values(by='date', ascending = True)
        all_dates_costs_mean = all_dates_costs_df.groupby(['date']).mean().head(most_comm)
        return all_dates_costs_mean
    
    @staticmethod
    def distance_duration_aggregation(data):
        """
        Aggregate distance and duration of flights
        Flights do not have transfer
        """
        distance_duration = [(data[i]['distance'],data[i]['duration']) for i in range(len(data)) if data[i]['number_of_changes'] == 0]
        distance_duration_pd = pd.DataFrame(distance_duration, columns = ['duration', 'distance']).sort_values(by='distance')
        
        return distance_duration_pd
    
    
    def final_aggregation(self, data = None):
        """
        Returns all statistics in one dict
        """
        if data is None:
            print('Did not recieve the answer')
            return None
        else:
            number_of_chages_value_agg= self.number_of_chages_value(data)
            gates_agg = self.gates_aggregation(data)
            dates_costs_agg = self.dates_costs_aggregation(data)
            distance_duration_agg = self.distance_duration_aggregation(data)
        
        return {'gates_agg': gates_agg, 
                'dates_costs_agg': dates_costs_agg, 
                'distance_duration_agg': distance_duration_agg,
                'number_of_chages_value_agg': number_of_chages_value_agg}
    
    
    if __name__ == '__main__':
        print('This is a parser for Aviasales API')