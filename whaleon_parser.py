#!/usr/bin/env python3
"""
Whaleon Log Parser
Parses whaleon logs and extracts structured data.
"""

import re
from datetime import datetime
from typing import Dict, Optional, Tuple


class WhaleonLogParser:
    """Parses whaleon logs and extracts structured information."""

    # Regex patterns for different log types
    PATTERNS = {
        "task_completed": re.compile(
            r"StateChange \[([^\]]+)\] ([A-Z0-9-]+) completed, Task size: (\d+), Duration: (\d+)s, Difficulty: (\w+)"
        ),
        "task_ready": re.compile(
            r"StateChange \[([^\]]+)\] Task completed, ready for next task"
        ),
        "waiting": re.compile(
            r"Waiting \[([^\]]+)\] Step (\d+) of (\d+): Waiting - ready for next task \((\d+)\) seconds"
        ),
        "difficulty_adjusted": re.compile(
            r"Success \[([^\]]+)\] Server adjusted difficulty: requested (\w+), assigned (\w+) \(reputation gating\)"
        ),
        "task_got": re.compile(
            r"Success \[([^\]]+)\] Step (\d+) of (\d+): Got task ([A-Z0-9-]+)"
        ),
        "task_proving": re.compile(
            r"StateChange \[([^\]]+)\] Step (\d+) of (\d+): Proving task ([A-Z0-9-]+)"
        ),
        "proof_generated": re.compile(
            r"Success \[([^\]]+)\] Step (\d+) of (\d+): Proof generated for task ([A-Z0-9-]+)"
        ),
        "proof_submitting": re.compile(
            r"StateChange \[([^\]]+)\] Step (\d+) of (\d+): Submitting proof for task ([A-Z0-9-]+)\.\.\."
        ),
        "proof_submitted": re.compile(
            r"Success \[([^\]]+)\] Step (\d+) of (\d+): Proof submitted successfully for task ([A-Z0-9-]+)"
        ),
    }

    @classmethod
    def parse_log_line(cls, log_line: str) -> Dict:
        """
        Parse a whaleon log line and return structured data.

        Returns:
            Dict with parsed information or None if not a whaleon log
        """
        log_line = log_line.strip()

        # Extract log type and timestamp
        log_type, timestamp, message = cls._extract_basic_info(log_line)
        if not log_type:
            return None

        # Parse based on log type
        parsed_data = {
            "raw_log": log_line,
            "log_type": log_type,
            "timestamp": timestamp,
            "message": message,
            "parsed_data": {},
        }

        # Apply specific parsing based on log type
        if log_type == "StateChange":
            parsed_data["parsed_data"] = cls._parse_state_change(message, timestamp)
        elif log_type == "Success":
            parsed_data["parsed_data"] = cls._parse_success(message, timestamp)
        elif log_type == "Waiting":
            parsed_data["parsed_data"] = cls._parse_waiting(message, timestamp)

        return parsed_data

    @classmethod
    def _extract_basic_info(
        cls, log_line: str
    ) -> Tuple[Optional[str], Optional[str], Optional[str]]:
        """Extract basic log type, timestamp, and message."""
        # Pattern: LogType [timestamp] message
        match = re.match(r"^(\w+)\s+\[([^\]]+)\]\s+(.+)$", log_line)
        if match:
            return match.group(1), match.group(2), match.group(3)
        return None, None, None

    @classmethod
    def _parse_state_change(cls, message: str, timestamp: str) -> Dict:
        """Parse StateChange log messages."""
        parsed = {}

        # Task completed
        match = cls.PATTERNS["task_completed"].match(
            f"StateChange [{timestamp}] {message}"
        )
        if match:
            parsed.update(
                {
                    "event": "task_completed",
                    "task_id": match.group(2),
                    "task_size": int(match.group(3)),
                    "duration": int(match.group(4)),
                    "difficulty": match.group(5),
                }
            )
            return parsed

        # Task ready
        match = cls.PATTERNS["task_ready"].match(f"StateChange [{timestamp}] {message}")
        if match:
            parsed.update({"event": "task_ready"})
            return parsed

        # Task proving
        match = cls.PATTERNS["task_proving"].match(
            f"StateChange [{timestamp}] {message}"
        )
        if match:
            parsed.update(
                {
                    "event": "task_proving",
                    "step": int(match.group(2)),
                    "total_steps": int(match.group(3)),
                    "task_id": match.group(4),
                }
            )
            return parsed

        # Proof submitting
        match = cls.PATTERNS["proof_submitting"].match(
            f"StateChange [{timestamp}] {message}"
        )
        if match:
            parsed.update(
                {
                    "event": "proof_submitting",
                    "step": int(match.group(2)),
                    "total_steps": int(match.group(3)),
                    "task_id": match.group(4),
                }
            )
            return parsed

        # Default state change
        parsed.update({"event": "state_change", "message": message})
        return parsed

    @classmethod
    def _parse_success(cls, message: str, timestamp: str) -> Dict:
        """Parse Success log messages."""
        parsed = {}

        # Difficulty adjusted
        match = cls.PATTERNS["difficulty_adjusted"].match(
            f"Success [{timestamp}] {message}"
        )
        if match:
            parsed.update(
                {
                    "event": "difficulty_adjusted",
                    "requested_difficulty": match.group(2),
                    "assigned_difficulty": match.group(3),
                }
            )
            return parsed

        # Task got
        match = cls.PATTERNS["task_got"].match(f"Success [{timestamp}] {message}")
        if match:
            parsed.update(
                {
                    "event": "task_got",
                    "step": int(match.group(2)),
                    "total_steps": int(match.group(3)),
                    "task_id": match.group(4),
                }
            )
            return parsed

        # Proof generated
        match = cls.PATTERNS["proof_generated"].match(
            f"Success [{timestamp}] {message}"
        )
        if match:
            parsed.update(
                {
                    "event": "proof_generated",
                    "step": int(match.group(2)),
                    "total_steps": int(match.group(3)),
                    "task_id": match.group(4),
                }
            )
            return parsed

        # Proof submitted
        match = cls.PATTERNS["proof_submitted"].match(
            f"Success [{timestamp}] {message}"
        )
        if match:
            parsed.update(
                {
                    "event": "proof_submitted",
                    "step": int(match.group(2)),
                    "total_steps": int(match.group(3)),
                    "task_id": match.group(4),
                }
            )
            return parsed

        # Default success
        parsed.update({"event": "success", "message": message})
        return parsed

    @classmethod
    def _parse_waiting(cls, message: str, timestamp: str) -> Dict:
        """Parse Waiting log messages."""
        parsed = {}

        # Waiting for next task
        match = cls.PATTERNS["waiting"].match(f"Waiting [{timestamp}] {message}")
        if match:
            parsed.update(
                {
                    "event": "waiting_for_task",
                    "step": int(match.group(2)),
                    "total_steps": int(match.group(3)),
                    "wait_seconds": int(match.group(4)),
                }
            )
            return parsed

        # Default waiting
        parsed.update({"event": "waiting", "message": message})
        return parsed

    @classmethod
    def get_log_priority(cls, log_type: str, event: str) -> int:
        """
        Get priority level for log display (lower = higher priority).

        Returns:
            Priority level (1-5, where 1 is highest priority)
        """
        priority_map = {
            "task_completed": 1,
            "proof_submitted": 1,
            "difficulty_adjusted": 2,
            "task_got": 2,
            "proof_generated": 2,
            "task_proving": 3,
            "proof_submitting": 3,
            "task_ready": 3,
            "waiting_for_task": 4,
            "state_change": 4,
            "success": 4,
            "waiting": 5,
        }

        return priority_map.get(event, 5)

    @classmethod
    def get_log_color(cls, log_type: str, event: str) -> str:
        """
        Get color code for log display.

        Returns:
            Color name for UI display
        """
        color_map = {
            "task_completed": "green",
            "proof_submitted": "green",
            "difficulty_adjusted": "blue",
            "task_got": "blue",
            "proof_generated": "blue",
            "task_proving": "yellow",
            "proof_submitting": "yellow",
            "task_ready": "yellow",
            "waiting_for_task": "orange",
            "state_change": "white",
            "success": "white",
            "waiting": "gray",
        }

        return color_map.get(event, "white")
