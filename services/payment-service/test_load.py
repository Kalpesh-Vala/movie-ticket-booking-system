"""
Load Testing for Payment Service
Tests performance, scalability, and stability under various load conditions
"""

import pytest
import asyncio
import aiohttp
import time
import statistics
from concurrent.futures import ThreadPoolExecutor
import json
import uuid
from typing import List, Dict, Any


class LoadTestPaymentService:
    """Load testing class for Payment Service"""

    def __init__(self, base_url: str = "http://localhost:8003"):
        self.base_url = base_url
        self.results = []

    async def single_payment_request(self, session: aiohttp.ClientSession, booking_id: str = None) -> Dict[str, Any]:
        """Make a single payment request and measure response time"""
        start_time = time.time()
        
        payment_data = {
            "booking_id": booking_id or f"booking_{uuid.uuid4().hex[:8]}",
            "amount": 150.00,
            "payment_method": "credit_card",
            "payment_details": {
                "card_number": "4111111111111111",
                "cvv": "123",
                "expiry_month": "12",
                "expiry_year": "2025",
                "cardholder_name": "Test User"
            }
        }

        try:
            async with session.post(f"{self.base_url}/payments", json=payment_data) as response:
                response_time = time.time() - start_time
                status_code = response.status
                response_data = await response.json()
                
                return {
                    "status_code": status_code,
                    "response_time": response_time,
                    "success": response_data.get("success", False),
                    "error": None
                }
        except Exception as e:
            response_time = time.time() - start_time
            return {
                "status_code": None,
                "response_time": response_time,
                "success": False,
                "error": str(e)
            }

    async def load_test_concurrent_requests(self, num_requests: int = 100, concurrency: int = 10) -> Dict[str, Any]:
        """Test concurrent payment requests"""
        print(f"🚀 Starting load test: {num_requests} requests with {concurrency} concurrent connections")
        
        connector = aiohttp.TCPConnector(limit=concurrency)
        timeout = aiohttp.ClientTimeout(total=30)
        
        async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
            # Create semaphore to limit concurrency
            semaphore = asyncio.Semaphore(concurrency)
            
            async def bounded_request():
                async with semaphore:
                    return await self.single_payment_request(session)
            
            # Execute all requests
            start_time = time.time()
            tasks = [bounded_request() for _ in range(num_requests)]
            results = await asyncio.gather(*tasks, return_exceptions=True)
            total_time = time.time() - start_time
            
            # Process results
            successful_requests = [r for r in results if isinstance(r, dict) and r.get("success")]
            failed_requests = [r for r in results if isinstance(r, dict) and not r.get("success")]
            error_requests = [r for r in results if isinstance(r, Exception)]
            
            response_times = [r["response_time"] for r in results if isinstance(r, dict)]
            
            return {
                "total_requests": num_requests,
                "total_time": total_time,
                "requests_per_second": num_requests / total_time,
                "successful_requests": len(successful_requests),
                "failed_requests": len(failed_requests),
                "error_requests": len(error_requests),
                "success_rate": len(successful_requests) / num_requests * 100,
                "avg_response_time": statistics.mean(response_times) if response_times else 0,
                "min_response_time": min(response_times) if response_times else 0,
                "max_response_time": max(response_times) if response_times else 0,
                "median_response_time": statistics.median(response_times) if response_times else 0,
                "p95_response_time": self.percentile(response_times, 95) if response_times else 0,
                "p99_response_time": self.percentile(response_times, 99) if response_times else 0
            }

    async def load_test_sustained_load(self, duration_seconds: int = 60, requests_per_second: int = 10) -> Dict[str, Any]:
        """Test sustained load over time"""
        print(f"📈 Starting sustained load test: {requests_per_second} RPS for {duration_seconds} seconds")
        
        results = []
        start_time = time.time()
        end_time = start_time + duration_seconds
        
        connector = aiohttp.TCPConnector(limit=50)
        timeout = aiohttp.ClientTimeout(total=30)
        
        async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
            while time.time() < end_time:
                batch_start = time.time()
                
                # Create batch of requests
                tasks = [self.single_payment_request(session) for _ in range(requests_per_second)]
                batch_results = await asyncio.gather(*tasks, return_exceptions=True)
                results.extend([r for r in batch_results if isinstance(r, dict)])
                
                # Wait for next second
                batch_duration = time.time() - batch_start
                if batch_duration < 1.0:
                    await asyncio.sleep(1.0 - batch_duration)
        
        total_requests = len(results)
        successful_requests = [r for r in results if r.get("success")]
        failed_requests = [r for r in results if not r.get("success")]
        response_times = [r["response_time"] for r in results]
        
        return {
            "duration": duration_seconds,
            "target_rps": requests_per_second,
            "total_requests": total_requests,
            "actual_rps": total_requests / duration_seconds,
            "successful_requests": len(successful_requests),
            "failed_requests": len(failed_requests),
            "success_rate": len(successful_requests) / total_requests * 100 if total_requests > 0 else 0,
            "avg_response_time": statistics.mean(response_times) if response_times else 0,
            "median_response_time": statistics.median(response_times) if response_times else 0,
            "p95_response_time": self.percentile(response_times, 95) if response_times else 0
        }

    async def load_test_spike_traffic(self) -> Dict[str, Any]:
        """Test handling of traffic spikes"""
        print("⚡ Starting spike traffic test")
        
        results = {}
        
        # Normal load
        print("📊 Phase 1: Normal load (10 requests)")
        results["normal_load"] = await self.load_test_concurrent_requests(10, 5)
        
        await asyncio.sleep(2)
        
        # Spike load
        print("🌋 Phase 2: Spike load (100 requests)")
        results["spike_load"] = await self.load_test_concurrent_requests(100, 20)
        
        await asyncio.sleep(2)
        
        # Recovery
        print("🔄 Phase 3: Recovery (10 requests)")
        results["recovery_load"] = await self.load_test_concurrent_requests(10, 5)
        
        return results

    async def load_test_mixed_scenarios(self) -> Dict[str, Any]:
        """Test mixed payment scenarios"""
        print("🎭 Starting mixed scenarios test")
        
        connector = aiohttp.TCPConnector(limit=20)
        timeout = aiohttp.ClientTimeout(total=30)
        
        async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
            tasks = []
            
            # Different payment amounts
            amounts = [50.0, 100.0, 150.0, 200.0, 500.0, 1000.0]
            payment_methods = ["credit_card", "debit_card", "digital_wallet", "net_banking"]
            
            for i in range(50):
                amount = amounts[i % len(amounts)]
                method = payment_methods[i % len(payment_methods)]
                
                payment_data = {
                    "booking_id": f"booking_{uuid.uuid4().hex[:8]}",
                    "amount": amount,
                    "payment_method": method,
                    "payment_details": {
                        "card_number": "4111111111111111",
                        "cvv": "123",
                        "expiry_month": "12",
                        "expiry_year": "2025",
                        "cardholder_name": "Test User"
                    }
                }
                
                async def make_request(data):
                    start_time = time.time()
                    try:
                        async with session.post(f"{self.base_url}/payments", json=data) as response:
                            response_time = time.time() - start_time
                            response_data = await response.json()
                            return {
                                "amount": data["amount"],
                                "method": data["payment_method"],
                                "success": response_data.get("success", False),
                                "response_time": response_time
                            }
                    except Exception as e:
                        return {
                            "amount": data["amount"],
                            "method": data["payment_method"],
                            "success": False,
                            "response_time": time.time() - start_time,
                            "error": str(e)
                        }
                
                tasks.append(make_request(payment_data))
            
            results = await asyncio.gather(*tasks)
            
            # Analyze by amount and method
            by_amount = {}
            by_method = {}
            
            for result in results:
                amount = result["amount"]
                method = result["method"]
                
                if amount not in by_amount:
                    by_amount[amount] = {"success": 0, "total": 0, "avg_time": 0}
                if method not in by_method:
                    by_method[method] = {"success": 0, "total": 0, "avg_time": 0}
                
                by_amount[amount]["total"] += 1
                by_method[method]["total"] += 1
                
                if result["success"]:
                    by_amount[amount]["success"] += 1
                    by_method[method]["success"] += 1
                
                by_amount[amount]["avg_time"] += result["response_time"]
                by_method[method]["avg_time"] += result["response_time"]
            
            # Calculate averages
            for amount_data in by_amount.values():
                if amount_data["total"] > 0:
                    amount_data["avg_time"] /= amount_data["total"]
                    amount_data["success_rate"] = amount_data["success"] / amount_data["total"] * 100
            
            for method_data in by_method.values():
                if method_data["total"] > 0:
                    method_data["avg_time"] /= method_data["total"]
                    method_data["success_rate"] = method_data["success"] / method_data["total"] * 100
            
            return {
                "total_requests": len(results),
                "by_amount": by_amount,
                "by_method": by_method,
                "overall_success_rate": sum(1 for r in results if r["success"]) / len(results) * 100
            }

    @staticmethod
    def percentile(data: List[float], p: int) -> float:
        """Calculate percentile"""
        if not data:
            return 0
        sorted_data = sorted(data)
        index = (p / 100) * (len(sorted_data) - 1)
        if index.is_integer():
            return sorted_data[int(index)]
        else:
            lower = sorted_data[int(index)]
            upper = sorted_data[int(index) + 1]
            return lower + (upper - lower) * (index - int(index))

    def print_results(self, results: Dict[str, Any], test_name: str):
        """Print formatted test results"""
        print(f"\n{'='*50}")
        print(f"📊 {test_name} Results")
        print(f"{'='*50}")
        
        if isinstance(results, dict) and "total_requests" in results:
            print(f"Total Requests: {results['total_requests']}")
            print(f"Successful: {results['successful_requests']} ({results['success_rate']:.2f}%)")
            print(f"Failed: {results['failed_requests']}")
            
            if "requests_per_second" in results:
                print(f"Requests/Second: {results['requests_per_second']:.2f}")
            
            print(f"Avg Response Time: {results['avg_response_time']*1000:.2f}ms")
            print(f"Median Response Time: {results['median_response_time']*1000:.2f}ms")
            print(f"95th Percentile: {results['p95_response_time']*1000:.2f}ms")
            
            if "p99_response_time" in results:
                print(f"99th Percentile: {results['p99_response_time']*1000:.2f}ms")
        
        print(f"{'='*50}\n")


async def run_all_load_tests():
    """Run all load tests"""
    load_tester = LoadTestPaymentService()
    
    print("🚀 Starting Payment Service Load Tests")
    print("="*60)
    
    # Test 1: Concurrent requests
    print("\n🧪 Test 1: Concurrent Requests")
    concurrent_results = await load_tester.load_test_concurrent_requests(50, 10)
    load_tester.print_results(concurrent_results, "Concurrent Requests (50 requests, 10 concurrent)")
    
    # Test 2: Sustained load
    print("\n🧪 Test 2: Sustained Load")
    sustained_results = await load_tester.load_test_sustained_load(30, 5)
    load_tester.print_results(sustained_results, "Sustained Load (5 RPS for 30 seconds)")
    
    # Test 3: Spike traffic
    print("\n🧪 Test 3: Spike Traffic")
    spike_results = await load_tester.load_test_spike_traffic()
    print("Spike Traffic Results:")
    for phase, results in spike_results.items():
        load_tester.print_results(results, f"Spike Test - {phase}")
    
    # Test 4: Mixed scenarios
    print("\n🧪 Test 4: Mixed Scenarios")
    mixed_results = await load_tester.load_test_mixed_scenarios()
    print(f"Mixed Scenarios - Overall Success Rate: {mixed_results['overall_success_rate']:.2f}%")
    print("\nBy Payment Method:")
    for method, data in mixed_results['by_method'].items():
        print(f"  {method}: {data['success_rate']:.2f}% success, {data['avg_time']*1000:.2f}ms avg")
    
    print("\n✅ All load tests completed!")


if __name__ == "__main__":
    # Run load tests
    asyncio.run(run_all_load_tests())