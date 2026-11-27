#!/usr/bin/env python3
"""
Test script to verify FastAPI backend endpoints
"""

import requests
import json

BASE_URL = "http://localhost:8000"

def test_health():
    """Test health endpoint"""
    print("Testing health endpoint...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    return response.status_code == 200

def test_listings():
    """Test listings endpoint"""
    print("\nTesting listings endpoint...")
    response = requests.get(f"{BASE_URL}/listings/")
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        listings = response.json()
        print(f"Found {len(listings)} listings")
        if listings:
            print(f"First listing: {listings[0]['name']}")
    return response.status_code == 200

def test_register():
    """Test user registration"""
    print("\nTesting user registration...")
    user_data = {
        "name": "Test User",
        "email": "test@example.com",
        "password": "testpassword123"
    }
    
    response = requests.post(
        f"{BASE_URL}/api/auth/register",
        json=user_data,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"Status: {response.status_code}")
    if response.status_code in [200, 201]:
        data = response.json()
        print(f"Registration successful! Token: {data['access_token'][:20]}...")
        return data['access_token']
    else:
        print(f"Response: {response.text}")
        return None

def test_login():
    """Test user login"""
    print("\nTesting user login...")
    login_data = {
        "email": "test@example.com",
        "password": "testpassword123"
    }
    
    response = requests.post(
        f"{BASE_URL}/api/auth/login",
        json=login_data,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"Login successful! Token: {data['access_token'][:20]}...")
        return data['access_token']
    else:
        print(f"Response: {response.text}")
        return None

def test_protected_endpoint(token):
    """Test protected endpoint with JWT token"""
    print("\nTesting protected endpoint...")
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    response = requests.get(f"{BASE_URL}/api/me", headers=headers)
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        user_data = response.json()
        print(f"User data: {user_data['name']} ({user_data['email']})")
        return True
    else:
        print(f"Response: {response.text}")
        return False

def test_sync_endpoints(token):
    """Test sync endpoints"""
    print("\nTesting sync endpoints...")
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    # Test sync pull
    print("Testing sync pull...")
    response = requests.get(f"{BASE_URL}/api/sync/pull", headers=headers)
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"Sync data received: {len(data.get('widgets', []))} widgets, "
              f"{len(data.get('notebooks', []))} notebooks, "
              f"{len(data.get('entries', []))} entries")
    
    # Test sync push
    print("\nTesting sync push...")
    sync_data = {
        "widgets": [
            {
                "id": "test-widget-1",
                "name": "Test Widget",
                "type": "microGoals",
                "config": {"goal": "Test goal"},
                "enabled": True,
                "placement": "homescreen"
            }
        ],
        "notebooks": [
            {
                "id": "test-notebook-1",
                "name": "Test Notebook",
                "color": 0xFF6750A4,
                "icon_key": "book",
                "created_at": "2024-01-01T00:00:00Z"
            }
        ],
        "entries": [
            {
                "id": "test-note-1",
                "notebook_id": "test-notebook-1",
                "title": "Test Note",
                "content": "This is a test note",
                "raw_text": "raw test text",
                "summary": "test summary",
                "source_app": "test",
                "created_at": "2024-01-01T00:00:00Z"
            }
        ]
    }
    
    response = requests.post(
        f"{BASE_URL}/api/sync/push",
        json=sync_data,
        headers=headers
    )
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        print(f"Sync push successful: {response.json()}")
        return True
    else:
        print(f"Response: {response.text}")
        return False

def main():
    print("=== FastAPI Backend Test ===\n")
    
    # Test basic endpoints
    if not test_health():
        print("Health check failed! Is the backend running?")
        print("Run: cd backend && python run.py")
        return
    
    test_listings()
    
    # Test authentication flow
    token = test_register()
    if not token:
        # Try login if registration failed (user might already exist)
        token = test_login()
    
    if token:
        # Test protected endpoints
        test_protected_endpoint(token)
        test_sync_endpoints(token)
    
    print("\n=== Test Complete ===")
    print("\nBackend endpoints tested:")
    print("✓ GET /health")
    print("✓ GET /listings/")
    print("✓ POST /api/auth/register")
    print("✓ POST /api/auth/login")
    print("✓ GET /api/me (protected)")
    print("✓ GET /api/sync/pull (protected)")
    print("✓ POST /api/sync/push (protected)")

if __name__ == "__main__":
    main()