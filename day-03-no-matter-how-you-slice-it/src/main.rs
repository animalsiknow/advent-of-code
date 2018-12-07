use std::fs;
use std::io::{self, BufRead};
use std::path;

type Range = std::ops::Range<u32>;

fn range_overlaps(left: &Range, right: &Range) -> bool {
    let start = left.start.max(right.start);
    let end = left.end.min(right.end);
    start < end
}

#[derive(Clone, Debug, Eq, PartialEq)]
struct Rectangle {
    x: Range,
    y: Range,
}

impl Rectangle {
    fn overlaps(&self, other: &Rectangle) -> bool {
        range_overlaps(&self.x, &other.x) && range_overlaps(&self.y, &other.y)
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
struct Claim {
    id: u32,
    rectangle: Rectangle,
}

fn read_claims<Path: AsRef<path::Path>>(path: Path) -> io::Result<Vec<Claim>> {
    let regex = regex::Regex::new(r#"^#(\d+) @ (\d+),(\d+): (\d+)x(\d+)$"#).unwrap();

    let file = fs::File::open(path)?;
    let reader = io::BufReader::new(file);

    let mut claims = vec![];
    for line in reader.lines() {
        if let Some(captures) = regex.captures(line?.as_str()) {
            let get =
                |index| u32::from_str_radix(captures.get(index).unwrap().as_str(), 10).unwrap();
            let id = get(1);
            let x = get(2);
            let y = get(3);
            let w = get(4);
            let h = get(5);
            let rectangle = Rectangle {
                x: x..(x + w),
                y: y..(y + h),
            };
            claims.push(Claim { id, rectangle })
        }
    }

    return Ok(claims);
}

fn main() -> io::Result<()> {
    let claims = read_claims("./no-matter-how-you-slice-it.txt")?;

    let (w, h) = claims.iter().fold((0, 0), |(w, h), claim| {
        (
            usize::max(w, claim.rectangle.x.end as usize),
            usize::max(h, claim.rectangle.y.end as usize),
        )
    });

    let mut fabric = vec![0u16; w * h];
    for claim in claims.iter() {
        for x in claim.rectangle.x.clone() {
            for y in claim.rectangle.y.clone() {
                fabric[x as usize + w * y as usize] += 1;
            }
        }
    }

    let overlapping_area = fabric.iter().fold(0, |area, &num_claim| {
        area + if num_claim > 1 { 1 } else { 0 }
    });
    println!("overlapping area: {}", overlapping_area);

    'outer: for claim in claims.iter() {
        for other_claim in claims.iter() {
            if claim.rectangle.overlaps(&other_claim.rectangle) && claim.id != other_claim.id {
                continue 'outer;
            }
        }

        println!("non-overlapping claim: {}", claim.id);
        return Ok(());
    }

    Ok(())
}
