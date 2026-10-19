import pandas as pd
import numpy as np

def clean_and_transform_taxi_data(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df.columns = [col.lower().strip() for col in df.columns]

    required_cols = [
        "tpep_pickup_datetime", 
        "tpep_dropoff_datetime", 
        "trip_distance", 
        "passenger_count", 
        "fare_amount", 
        "tip_amount", 
        "total_amount"
    ]
    missing = [c for c in required_cols if c not in df.columns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    df["tpep_pickup_datetime"] = pd.to_datetime(df["tpep_pickup_datetime"])
    df["tpep_dropoff_datetime"] = pd.to_datetime(df["tpep_dropoff_datetime"])

    df["trip_duration_minutes"] = (
        (df["tpep_dropoff_datetime"] - df["tpep_pickup_datetime"]).dt.total_seconds() / 60.0
    ).round(2)

    valid_mask = (
        (df["trip_duration_minutes"] >= 1.0) & 
        (df["trip_duration_minutes"] <= 240.0) &
        (df["trip_distance"] > 0.0) & 
        (df["passenger_count"] > 0) &
        (df["fare_amount"] > 0.0)
    )
    df_clean = df.loc[valid_mask].copy()

    df_clean["tip_percentage"] = np.where(
        df_clean["fare_amount"] > 0,
        ((df_clean["tip_amount"] / df_clean["fare_amount"]) * 100.0).round(2),
        0.0
    )
    df_clean["average_speed_mph"] = (
        df_clean["trip_distance"] / (df_clean["trip_duration_minutes"] / 60.0)
    ).round(2)

    return df_clean
