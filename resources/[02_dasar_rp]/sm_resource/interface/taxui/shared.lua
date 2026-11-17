VehicleClassification = {}
local Config = require 'interface.taxui.config'

-- Function to check if vehicle is import based on brand
function VehicleClassification.IsImportVehicle(brand)
    if not brand then return false end
    return Config.ImportBrands[brand] == true
end

-- Function to get vehicle value
function VehicleClassification.GetVehicleValue(brand)
    if VehicleClassification.IsImportVehicle(brand) then
        return Config.VehicleValues.import
    end
    return Config.VehicleValues.lokal
end

-- Function to classify all player vehicles
function VehicleClassification.ClassifyVehicles(vehicles)
    local classification = {
        import = {
            count = 0,
            value = 0,
            vehicles = {}
        },
        local_vehicles = {
            count = 0,
            value = 0,
            vehicles = {}
        },
        total = {
            count = 0,
            value = 0
        }
    }
    
    if not vehicles or type(vehicles) ~= 'table' then
        return classification
    end
    
    for _, vehicle in pairs(vehicles) do
        if vehicle and vehicle.vehicle then
            local brand = vehicle.vehicle.brand or 'Unknown'
            local model = vehicle.vehicle.model or vehicle.vehicle
            local isImport = VehicleClassification.IsImportVehicle(brand)
            local value = VehicleClassification.GetVehicleValue(brand)
            
            if isImport then
                classification.import.count = classification.import.count + 1
                classification.import.value = classification.import.value + value
                table.insert(classification.import.vehicles, {
                    model = model,
                    brand = brand,
                    value = value,
                    plate = vehicle.plate
                })
            else
                classification.local_vehicles.count = classification.local_vehicles.count + 1
                classification.local_vehicles.value = classification.local_vehicles.value + value
                table.insert(classification.local_vehicles.vehicles, {
                    model = model,
                    brand = brand,
                    value = value,
                    plate = vehicle.plate
                })
            end
            
            classification.total.count = classification.total.count + 1
            classification.total.value = classification.total.value + value
        end
    end
    
    return classification
end

-- Function to get detailed vehicle breakdown
function VehicleClassification.GetVehicleBreakdown(vehicles)
    local breakdown = {
        import_vehicles = {},
        local_vehicles = {},
        summary = {
            total_import = 0,
            total_local = 0,
            total_value = 0,
            import_count = 0,
            local_count = 0
        }
    }
    
    if not vehicles or type(vehicles) ~= 'table' then
        return breakdown
    end
    
    for _, vehicle in pairs(vehicles) do
        if vehicle and vehicle.vehicle then
            local brand = vehicle.vehicle.brand or 'Unknown'
            local model = vehicle.vehicle.model or vehicle.vehicle
            local isImport = VehicleClassification.IsImportVehicle(brand)
            local value = VehicleClassification.GetVehicleValue(brand)
            
            local vehicleData = {
                model = model,
                brand = brand,
                value = value,
                plate = vehicle.plate or 'N/A',
                garage = vehicle.garage or 'Unknown'
            }
            
            if isImport then
                table.insert(breakdown.import_vehicles, vehicleData)
                breakdown.summary.total_import = breakdown.summary.total_import + value
                breakdown.summary.import_count = breakdown.summary.import_count + 1
            else
                table.insert(breakdown.local_vehicles, vehicleData)
                breakdown.summary.total_local = breakdown.summary.total_local + value
                breakdown.summary.local_count = breakdown.summary.local_count + 1
            end
        end
    end
    
    breakdown.summary.total_value = breakdown.summary.total_import + breakdown.summary.total_local
    
    return breakdown
end

return VehicleClassification