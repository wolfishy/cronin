import pyautogui
import time
import sys

# Configure pyautogui
pyautogui.FAILSAFE = True  # Move mouse to upper-left corner to abort
pyautogui.PAUSE = 0.5  # Small pause between actions for stability


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
            # Simulate key press
            pyautogui.press(key)
            print(f"Pressed '{key}' at {time.ctime()}")

            # Wait for the next interval
            time.sleep(interval)

        except Exception as e:
            print(f"Error: {e}")
            time.sleep(10)  # Retry after error

        except KeyboardInterrupt:
            print("Script stopped by user")
            sys.exit(0)


if __name__ == "__main__":
    # Simulate spacebar press every 2 minutes
    # Ensure the target window (e.g., Terminal, VS Code) is focused before running
    press_key(key="space", interval=120)
