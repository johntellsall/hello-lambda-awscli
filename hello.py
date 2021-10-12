# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

"""
Purpose

Shows how to implement an AWS Lambda function that handles input from direct
invocation.
"""

import logging
import math

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Define a list of Python lambda functions that are called by this AWS Lambda function.
ACTIONS = {
    "square": lambda x: x * x,
    "square root": lambda x: math.sqrt(x),
    "increment": lambda x: x + 1,
    "decrement": lambda x: x - 1,
}


def handler(event, context):
    """
    Accepts an action and a number, performs the specified action on the number,
    and returns the result.

    :param event: The event dict that contains the parameters sent when the function
                  is invoked.
    :param context: The context in which the function is called.
    :return: The result of the specified action.
    """
    logger.info("Event: %s", event)

    try:
        result = ACTIONS[event["action"]](event["number"])
        logger.info("Calculated result of %s", result)

        response = {"result": result, "version": 841}
        logger.info("response %s", response)

        return response
    except KeyError as err:
        # TODO: more here
        return {"error": str(err)}
