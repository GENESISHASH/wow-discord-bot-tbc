#!/bin/bash
echo "Starting service.."
forever -c iced start app.iced
forever list
echo "Finished starting service"

