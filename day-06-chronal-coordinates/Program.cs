using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Collections.Immutable;
using System.IO;
using static System.Linq.Enumerable;
using static System.Math;

namespace ChronalCoordinates
{

internal struct Point : IComparable<Point>, IComparable, IEquatable<Point>
{
    public int X { get; }
    public int Y { get; }

    public Point(int x, int y)
    {
        X = x;
        Y = y;
    }

    public int Distance(Point other) =>
        Abs(X - other.X) + Abs(Y - other.Y);

    public int CompareTo(Point other)
    {
        var xComparison = X.CompareTo(other.X);
        if (xComparison != 0) {
            return xComparison;
        }

        return Y.CompareTo(other.Y);
    }

    public int CompareTo(object otherObject)
    {
        if (otherObject is Point other) {
            return CompareTo(other);
        }

        throw new ArgumentException();

    }

    public bool Equals(Point other)
    {
        return X == other.X && Y == other.Y;
    }

    public override bool Equals(object otherObject)
    {
        if (ReferenceEquals(null, otherObject)) {
            return false;
        }

        return otherObject is Point other && Equals(other);
    }

    public override int GetHashCode()
    {
        unchecked {
            return (X * 397) ^ Y;
        }
    }
}

internal struct Area
{
    public Point Site { get; }
    public int Size { get; }

    public Area(Point site, int size)
    {
        Site = site;
        Size = size;
    }
}

internal static class Program
{
    private static void Main(string[] args)
    {
        var points = Input();

        var xMin = int.MaxValue;
        var xMax = int.MinValue;
        var yMin = int.MaxValue;
        var yMax = int.MinValue;
        foreach (var point in points) {
            if (point.X < xMin) {
                xMin = point.X;
            } else if (xMax < point.X) {
                xMax = point.X;
            }

            if (point.Y < yMin) {
                yMin = point.Y;
            } else if (yMax < point.Y) {
                yMax = point.Y;
            }
        }

        var grid = (Point[,])Array.CreateInstance(
            typeof(Point),
            new[] {xMax - xMin + 1, yMax - yMin + 1},
            new[] {xMin, yMin});

        FillGridWithClosestPoints(grid, points);
        var boundaries = FindBoundaries(grid);
        var largestArea = ListAreas(grid).Where((area) => !boundaries.Contains(area.Site)).Max((area) => area.Size);
        Console.WriteLine($"largest area: {largestArea}");

        var areaWithin1000 = 0;
        const int buffer = 10;
        foreach (var x in Range(xMin - buffer, xMax + buffer)) {
            foreach (var y in Range(yMin - buffer, yMax + buffer)) {
                var currentPoint = new Point(x, y);
                if (points.Sum((point) => point.Distance(currentPoint)) < 10000) {
                    areaWithin1000 += 1;
                }
            }
        }

        Console.WriteLine($"area within 10000: {areaWithin1000}");
    }

    private static void FillGridWithClosestPoints(Point[,] grid, IList<Point> points)
    {
        foreach (var x in Range(grid.GetLowerBound(0), grid.GetLength(0))) {
            foreach (var y in Range(grid.GetLowerBound(1), grid.GetLength(1))) {
                var currentPoint = new Point(x, y);
                var closestPoint = default(Point);
                var closestDistance = int.MaxValue;
                var tied = false;

                foreach (var point in points) {
                    var currentDistance = currentPoint.Distance(point);
                    if (currentDistance < closestDistance) {
                        closestPoint = point;
                        closestDistance = currentDistance;
                        tied = false;
                    } else if (currentDistance == closestDistance) {
                        tied = true;
                    }
                }

                if (!tied) {
                    grid[x, y] = closestPoint;
                }
            }
        }
    }

    private static IImmutableSet<Point> FindBoundaries(Point[,] grid)
    {
        IEnumerable<Point> FindAllBoundaries()
        {
            var yMin = grid.GetLowerBound(1);
            var yMax = grid.GetUpperBound(1);
            foreach (var x in Range(grid.GetLowerBound(0), grid.GetLength(0))) {
                yield return grid[x, yMin];
                yield return grid[x, yMax];
            }

            var xMin = grid.GetLowerBound(0);
            var xMax = grid.GetUpperBound(0);
            foreach (var y in Range(grid.GetLowerBound(1), grid.GetLength(1))) {
                yield return grid[xMin, y];
                yield return grid[xMax, y];
            }
        }

        return FindAllBoundaries().ToImmutableSortedSet();
    }

    private static IEnumerable<Area> ListAreas(Point[,] grid)
    {
        var areas = new ConcurrentDictionary<Point, int>();
        foreach (var x in Range(grid.GetLowerBound(0), grid.GetLength(0))) {
            foreach (var y in Range(grid.GetLowerBound(1), grid.GetLength(1))) {
                areas.AddOrUpdate(grid[x, y], (_) => 1, (_, area) => area + 1);
            }
        }

        return areas.Select((kv) => new Area(kv.Key, kv.Value));
    }

    private static IList<Point> Input()
    {
        var points = new List<Point>();
        var assembly = typeof(Program).Assembly;
        var resource = assembly.GetManifestResourceStream("ChronalCoordinates.ChronalCoordinates.txt");
        using (var reader = new StreamReader(resource)) {
            string line;
            while ((line = reader.ReadLine()) != null) {
                var parts = line.Split(",");
                points.Add(new Point(int.Parse(parts[0]), int.Parse(parts[1])));
            }
        }

        return points;
    }
}

}
