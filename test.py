import pyautogui
import time
import sys
import random


def simulate_tab_switching(interval=60):
    """
    Simulate realistic tab switching and key presses to prevent Gitpod idle timeouts.
    Args:
        interval (int): Seconds between activities (default: 60 seconds).
    """
    print("Starting realistic tab switching simulation...")

    # List of tab numbers to switch to
    tab_numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]

    while True:
        try:
            # Go through all tabs
            for tab_num in tab_numbers:
                # Switch to tab using Ctrl + number
                pyautogui.hotkey("ctrl", str(tab_num))
                print(f"Switched to tab {tab_num} at {time.ctime()}")

                # Wait a bit like a real user
                time.sleep(2)

                pyautogui.press("space")
                pyautogui.press("backspace")

            # Wait 60 seconds after completing all tabs
            print(f"Completed all tabs, waiting {interval} seconds...")
            time.sleep(interval)

        except Exception as e:
            print(f"Error: {e}")
            time.sleep(10)

        except KeyboardInterrupt:
            print("Script stopped by user")
            sys.exit(0)


if __name__ == "__main__":
    simulate_tab_switching(interval=60)
