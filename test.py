import pyautogui
import time
import sys


def press_key(key="space", interval=120):
    """
    Simulate a key press in the active window to prevent Gitpod idle timeouts.
    Args:
        key (str): Key to press (default: 'space').
        interval (int): Seconds between key presses (default: 120 seconds).
    """
    print(f"Starting key press simulation for active window with key '{key}'")

    while True:
        try:
            pyautogui.press(key)
            print(f"Pressed '{key}' at {time.ctime()}")

            time.sleep(interval)

        except Exception as e:
            print(f"Error: {e}")
            time.sleep(10)

        except KeyboardInterrupt:
            print("Script stopped by user")
            sys.exit(0)


if __name__ == "__main__":
    press_key(key="space", interval=120)
