if turtle.getFuelLevel() == 0 then
    turtle.refuel(64)
end

for i = 1, 10 do
    turtle.forward()
    turtle.forward()
    turtle.forward()
    turtle.forward()
    turtle.turnRight()
end
