from datetime import datetime, timedelta
import numpy as np
import pandas as pd
import pytest

from src.transform import clean_and_transform_taxi_data


# ---------------------------------------------------------
# Fixtures
# ---------------------------------------------------------

@pytest.fixture
def mock_taxi_raw_dataframe() -> pd.DataFrame:
    """Creates a controlled sample DataFrame covering both valid and edge/invalid cases."""
    base_time = datetime(2026, 1, 15, 10, 0, 0)
    
    return pd.DataFrame({
        # Row 0: Valid standard trip (15 mins, 3.0 mi, $15 fare, $3 tip)
        # Row 1: Invalid - 0 minutes duration (dropoff == pickup)
        # Row 2: Invalid - negative fare amount
        # Row 3: Invalid - 0 passenger count
        # Row 4: Invalid - trip distance is 0.0
        # Row 5: Valid longer trip (30 mins, 10.0 mi, $40 fare, $10 tip)
        "tpep_pickup_datetime": [
            base_time,
            base_time,
            base_time,
            base_time,
            base_time,
            base_time,
        ],
        "tpep_dropoff_datetime": [
            base_time + timedelta(minutes=15),
            base_time,
            base_time + timedelta(minutes=20),
            base_time + timedelta(minutes=10),
            base_time + timedelta(minutes=10),
            base_time + timedelta(minutes=30),
        ],
        "trip_distance": [3.0, 1.2, 4.0, 2.5, 0.0, 10.0],
        "passenger_count": [1, 1, 1, 0, 1, 2],
        "fare_amount": [15.0, 12.0, -8.0, 10.0, 14.0, 40.0],
        "tip_amount": [3.0, 2.0, 0.0, 1.0, 2.0, 10.0],
        "total_amount": [18.0, 14.0, -8.0, 11.0, 16.0, 50.0],
    })


# ---------------------------------------------------------
# Unit Tests
# ---------------------------------------------------------

def test_feature_engineering_calculations(mock_taxi_raw_dataframe):
    """Verifies duration, tip percentage, and average speed calculations on valid records."""
    cleaned = clean_and_transform_taxi_data(mock_taxi_raw_dataframe)

    first_trip = cleaned.iloc[0]
    
    # 15 minutes trip
    assert first_trip["trip_duration_minutes"] == 15.0
    
    # tip % = (3.0 / 15.0) * 100 = 20.0%
    assert np.isclose(first_trip["tip_percentage"], 20.0)
    
    # speed = 3.0 miles / (15 / 60 hours) = 12.0 mph
    assert np.isclose(first_trip["average_speed_mph"], 12.0)


def test_filters_out_invalid_operational_records(mock_taxi_raw_dataframe):
    """Ensures dirty records (0 duration, negative fare, 0 passengers, 0 distance) are dropped."""
    cleaned = clean_and_transform_taxi_data(mock_taxi_raw_dataframe)

    # Out of 6 records, only index 0 and index 5 are fully valid
    assert len(cleaned) == 2
    
    # Ensure all remaining records respect clean bounds
    assert (cleaned["trip_duration_minutes"] >= 1.0).all()
    assert (cleaned["fare_amount"] > 0.0).all()
    assert (cleaned["passenger_count"] > 0).all()
    assert (cleaned["trip_distance"] > 0.0).all()


def test_missing_mandatory_columns_raises_exception():
    """Confirms pipeline fails early if crucial columns are missing from the input."""
    incomplete_df = pd.DataFrame({
        "trip_distance": [5.0],
        "fare_amount": [20.0],
    })

    with pytest.raises(ValueError, match="Missing required columns"):
        clean_and_transform_taxi_data(incomplete_df)


@pytest.mark.parametrize("tip,fare,expected_percent", [
    (0.0, 20.0, 0.0),
    (5.0, 20.0, 25.0),
    (10.0, 40.0, 25.0),
])
def test_tip_percentage_logic(tip, fare, expected_percent):
    """Verifies tipping math behavior under different scenarios."""
    base_time = datetime(2026, 1, 15, 12, 0, 0)
    df = pd.DataFrame({
        "tpep_pickup_datetime": [base_time],
        "tpep_dropoff_datetime": [base_time + timedelta(minutes=10)],
        "trip_distance": [2.0],
        "passenger_count": [1],
        "fare_amount": [fare],
        "tip_amount": [tip],
        "total_amount": [fare + tip],
    })
    
    transformed = clean_and_transform_taxi_data(df)
    assert np.isclose(transformed.iloc[0]["tip_percentage"], expected_percent)