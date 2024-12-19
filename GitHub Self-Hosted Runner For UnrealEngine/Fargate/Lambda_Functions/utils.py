import logging

class Logger:
    def __init__(self, name="Logger", global_title=None):
        self.logger = logging.getLogger(name)
        if not self.logger.hasHandlers():
            handler = logging.StreamHandler()
            formatter = logging.Formatter("[%(name)s] [%(levelname)s] %(message)s")
            handler.setFormatter(formatter)
            self.logger.addHandler(handler)
        self.logger.setLevel(logging.INFO)
        self.global_title = global_title
        self.function_title = None

    def info(self, message, title=None):
        self._log(message, title, level="info")

    def warning(self, message, title=None):
        self._log(message, title, level="warning")

    def error(self, message, title=None):
        self._log(message, title, level="error")

    def _log(self, message, title, level):
        title = self.function_title or self.global_title
        formatted_message = f"[{title}] {message}" if title else message

        if level == "info":
            self.logger.info(formatted_message)
        elif level == "warning":
            self.logger.warning(formatted_message)
        elif level == "error":
            self.logger.error(formatted_message)
        else:
            raise ValueError(f"Unsupported logging level: {level}")

    def set_function_title(self, title):
        self.function_title = title

    def reset_function_title(self):
        self.function_title = None
