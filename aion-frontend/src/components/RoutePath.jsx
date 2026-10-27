/** Ordered list of zones travelled by a route, with numbered markers. */
function RoutePath({ label, name, route }) {
  if (!Array.isArray(route) || route.length === 0) return null

  return (
    <div className="route-card">
      <div className="route-header">
        <span>{label}</span>
        <strong>{name}</strong>
      </div>

      <ol className="route-path">
        {route.map((location, index) => (
          <li className="route-location" key={`${location}-${index}`}>
            <div className="route-marker">{index + 1}</div>
            <span>{location}</span>
            {index < route.length - 1 && (
              <div className="route-connector" aria-hidden="true"></div>
            )}
          </li>
        ))}
      </ol>
    </div>
  )
}

export default RoutePath
